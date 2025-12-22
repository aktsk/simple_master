# frozen_string_literal: true

class Player < ApplicationRecord
  belongs_to :level, foreign_key: :lv, primary_key: :lv
  belongs_to :weapon
  belongs_to :armor
  has_many :player_items
  has_many :items, through: :player_items

  def items
    player_items.flat_map do |player_item|
      quantity = player_item.quantity.to_i
      next [] if quantity <= 0
      next [] unless player_item.item

      Array.new(quantity, player_item.item)
    end
  end

  def equip_weapon(weapon)
    return false unless weapon.is_a?(Weapon)

    record = find_item_record(weapon)
    return false unless record&.quantity.to_i.positive?

    update!(weapon_id: weapon.id)
    true
  end

  def equip_armor(armor)
    return false unless armor.is_a?(Armor)

    record = find_item_record(armor)
    return false unless record&.quantity.to_i.positive?

    update!(armor_id: armor.id)
    true
  end

  def attack_power
    base = level.attack
    bonus = (weapon&.attack || 0).to_f
    base + bonus
  end

  def defence_power
    base = level.defence
    bonus = (armor&.defence || 0).to_f
    base + bonus
  end

  def challenge_enemy(enemy, at: Time.current)
    return { ok: false, reason: :out_of_period } unless enemy.available?(at)
    player_attack = attack_power
    return { ok: false, reason: :attack_too_low } if player_attack <= enemy.defence.to_f

    cost = stamina_cost_for(enemy)
    return { ok: false, reason: :not_enough_stamina } unless consume_stamina(cost, at: at)

    apply_hp_regen!(at)

    player_hp = hp.to_f
    enemy_hp = enemy.hp.to_f
    player_damage = scaled_damage(player_attack, enemy.defence.to_f)
    enemy_damage = scaled_damage(enemy.attack.to_f, defence_power)

    while enemy_hp > 0 && player_hp > 0
      enemy_hp -= player_damage
      break if enemy_hp <= 0

      player_hp -= enemy_damage
    end

    self.hp = [player_hp, 0.0].max
    self.hp_updated_at = at

    if enemy_hp > 0
      save!
      return { ok: false, reason: :defeated }
    end

    gain_exp(enemy.exp.to_i)
    rewards = receive_rewards(enemy)
    leveled_up = consume_exp_for_level_up(at: at)
    cap_resources!(at)
    save!

    { ok: true, leveled_up: leveled_up, rewards: rewards }
  end

  def use_potion(potion, at: Time.current)
    return false unless potion
    item_record = find_item_record(potion)
    return false unless item_record

    apply_hp_regen!(at)
    heal_amount = potion.hp.to_f
    return false if heal_amount <= 0

    self.hp = [hp.to_f + heal_amount, max_hp].min
    self.hp_updated_at = at
    if item_record.quantity.to_i > 1
      item_record.update!(quantity: item_record.quantity.to_i - 1)
    else
      item_record.destroy!
    end
    save!
    true
  end

  def current_hp(at: Time.current)
    max = max_hp
    return 0.0 if max <= 0.0

    base = hp.nil? ? max : hp
    last = hp_updated_at || at
    recovered = recovered_amount(base, max, last, at, level.hp_recovery_sec)

    [base + recovered, max].min
  end

  def current_stamina(at: Time.current)
    max = max_stamina
    return 0 if max <= 0

    base = stamina.nil? ? max : stamina
    last = stamina_updated_at || at
    recovered = recovered_amount(base, max, last, at, level.stamina_recovery_sec)

    [(base + recovered).to_i, max].min
  end

  def max_hp
    level.hp
  end

  def max_stamina
    level.stamina
  end

  def self.find_by_lv(lv)
    find_by(lv: lv)
  end

  private

  def scaled_damage(attack, defence)
    return 0.0 if attack.to_f <= 0.0

    attack.to_f * 100.0 / (100.0 + defence.to_f)
  end

  def stamina_cost_for(enemy)
    [enemy.stamina_cost.to_i, 1].max
  end

  def apply_hp_regen!(at)
    self.hp = current_hp(at: at)
    self.hp_updated_at = at
  end

  def apply_stamina_regen!(at)
    self.stamina = current_stamina(at: at)
    self.stamina_updated_at = at
  end

  def recovered_amount(base, max, from_time, to_time, recovery_sec)
    return 0.0 if max <= base
    interval = recovery_sec.to_i
    return 0.0 if interval <= 0

    elapsed = (to_time - from_time).to_i
    return 0.0 if elapsed <= 0

    steps = elapsed / interval
    [steps.to_f, max - base].min
  end

  def consume_stamina(cost, at:)
    apply_stamina_regen!(at)
    return false if stamina.to_i < cost

    self.stamina = stamina.to_i - cost
    self.stamina_updated_at = at
    true
  end

  def gain_exp(amount)
    self.exp = exp.to_i + amount
  end

  def consume_exp_for_level_up(at:)
    leveled_up = false

    loop do
      current_level = level
      required = current_level.next_exp.to_i
      break if required <= 0
      break if exp.to_i < required

      next_level = Level.find_by(:lv, lv + 1)
      break unless next_level

      self.exp = exp.to_i - required
      self.lv = next_level.lv
      leveled_up = true
    end

    if leveled_up
      self.stamina = max_stamina
      self.stamina_updated_at = at
    end

    leveled_up
  end

  def cap_resources!(at)
    apply_hp_regen!(at)
    apply_stamina_regen!(at)

    self.hp = [hp.to_f, max_hp].min if max_hp.positive?
    self.stamina = [stamina.to_i, max_stamina].min if max_stamina.positive?
  end

  def receive_rewards(enemy)
    enemy.rewards.filter_map do |reward|
      next if reward.reward_type.nil? || reward.reward_id.nil?

      add_item(reward.reward_type, reward.reward_id)
    end
  end

  def find_item_record(item)
    player_items.find_by(item: item)
  end

  def add_item(item_type, item_id, amount = 1)
    item_class = item_type.safe_constantize
    unless item_class && item_class <= ItemReceivable
      fail ArgumentError, "Unsupported item_type: #{item_type}"
    end

    record = player_items.find_or_initialize_by(item_type: item_type, item_id: item_id)
    max_quantity = item_class.max_quantity
    quantity = record.quantity.to_i + amount
    quantity = [quantity, max_quantity].min if max_quantity
    record.quantity = quantity
    record.save!
    record
  end
end
