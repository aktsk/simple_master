# frozen_string_literal: true

class GameController < ActionController::Base # rubocop:disable Rails/ApplicationController
  skip_forgery_protection

  def show
    @player = current_player
    @now = Time.current
    @enemies =
      Enemy.available_at(@now)
           .sort_by { |enemy| [enemy.is_boss? ? 1 : 0, enemy.attack.to_f + enemy.defence.to_f + enemy.hp.to_f] }
    @potions = Potion.all
  end

  def play
    @player = current_player

    case params[:op]
    when "create_player"
      @player = Player.create!(name: player_name, lv: player_level)
      session[:player_id] = @player.id
      flash.now[:notice] = "Player created."
    when "challenge"
      enemy = Enemy.find_by_id(params[:enemy_id].to_i)
      if @player && enemy
        result = @player.challenge_enemy(enemy, at: Time.current)
        flash[:notice] = battle_message(result)
      else
        flash[:notice] = "Missing player or enemy."
      end
    when "potion"
      potion = Potion.find_by_id(params[:potion_id].to_i)
      flash.now[:notice] = if @player && potion
                             @player.use_potion(potion, at: Time.current) ? "Healed." : "Potion failed."
                           else
                             "Missing player or potion."
                           end
    when "equip_weapon"
      weapon = Weapon.find_by_id(params[:weapon_id].to_i)
      flash.now[:notice] = if @player && weapon
                             @player.equip_weapon(weapon) ? "Weapon equipped." : "Cannot equip weapon."
                           else
                             "Missing player or weapon."
                           end
    when "equip_armor"
      armor = Armor.find_by_id(params[:armor_id].to_i)
      flash.now[:notice] = if @player && armor
                             @player.equip_armor(armor) ? "Armor equipped." : "Cannot equip armor."
                           else
                             "Missing player or armor."
                           end
    end

    redirect_to root_path
  end

  private

  def current_player
    player_id = session[:player_id]
    return unless player_id

    Player.find_by(id: player_id)
  end

  def player_name
    name = params[:name].to_s.strip
    name.empty? ? "Hero" : name
  end

  def player_level
    1
  end

  def battle_message(result)
    return "No player." if result.nil?
    return "Win! Level up." if result[:ok] && result[:leveled_up]
    return "Win! Rewards #{result[:rewards].size}" if result[:ok]

    "Lost: #{result[:reason]}"
  end
end
