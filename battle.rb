require 'json'

PLAYER_POINTS = 100
MAX_ROUNDS    = 300
HP_PER_CON    = 20
DR_PER_AGI    = 0.5
DAMAGE_CAP    = 40
CRIT_CHANCE   = 0.10
CRIT_CAP      = (DAMAGE_CAP * 1.5).floor  # 60

# Opponent stats loaded from compiled binary — not human-readable in the container.
# Use `ruby battle.rb <opp1> <opp2> --simulate` to probe matchups instead.
OPPONENTS = Marshal.load(File.read(File.join(__dir__, 'opponents.dat'))).freeze

OPPONENT_NAMES = OPPONENTS.keys.freeze

def make_character(str:, agi:, con:)
  { str: str, agi: agi, con: con, hp: con * HP_PER_CON, dr: agi * DR_PER_AGI }
end

def attack(attacker, defender, rng)
  raw = attacker[:str]
  raw = rng.rand < CRIT_CHANCE ? [raw, CRIT_CAP].min : [raw, DAMAGE_CAP].min
  [raw - defender[:dr] + rng.rand(-1..1), 0].max
end

def single_battle(char_a, char_b, seed: 42)
  rng = Random.new(seed)
  a_hp = char_a[:hp].to_f
  b_hp = char_b[:hp].to_f
  rounds = 0
  while a_hp > 0 && b_hp > 0 && rounds < MAX_ROUNDS
    rounds += 1
    a_takes = attack(char_b, char_a, rng)
    b_takes = attack(char_a, char_b, rng)
    a_hp -= a_takes
    b_hp -= b_takes
  end
  { winner: a_hp > b_hp ? 'a' : 'b', rounds: rounds, a_hp: a_hp.round(1), b_hp: b_hp.round(1) }
end

def simulate_matchup(char_a, char_b, seeds: (1..100).to_a)
  results = seeds.map { |s| single_battle(char_a, char_b, seed: s) }
  wins_a = results.count { |r| r[:winner] == 'a' }
  { simulations: seeds.size, wins_a: wins_a, wins_b: seeds.size - wins_a,
    win_pct_a: (wins_a.to_f / seeds.size * 100).round(1),
    win_pct_b: ((seeds.size - wins_a).to_f / seeds.size * 100).round(1) }
end

def tournament(player, seed: 42)
  rng = Random.new(seed)
  bracket = OPPONENTS.values.shuffle(random: rng)
  a_hp = player[:hp].to_f
  fights = []
  bracket.each do |opp|
    b_hp = opp[:hp].to_f
    rounds = 0
    while a_hp > 0 && b_hp > 0 && rounds < MAX_ROUNDS
      rounds += 1
      a_takes = attack(opp, player, rng)
      b_takes = attack(player, opp, rng)
      a_hp -= a_takes
      b_hp -= b_takes
    end
    winner = a_hp > b_hp ? 'player' : 'opponent'
    fights << { winner: winner, player_hp_after: a_hp.round(1), rounds: rounds }
    break if winner != 'player'
  end
  won_all = fights.length == OPPONENTS.size && fights.all? { |f| f[:winner] == 'player' }
  { winner: won_all ? 'player' : 'opponent', fights_completed: fights.length, final_player_hp: a_hp.round(1) }
end

def simulate_tournament(player, seeds: (1..100).to_a)
  results = seeds.map { |s| tournament(player, seed: s) }
  wins = results.count { |r| r[:winner] == 'player' }
  { simulations: seeds.size, wins: wins, win_pct: (wins.to_f / seeds.size * 100).round(1) }
end

if __FILE__ == $0
  if ARGV.length < 2
    puts "Usage:"
    puts "  ruby battle.rb <opp1> <opp2> --simulate       # probe opponent matchup"
    puts "  ruby battle.rb <opp1> <opp2> [seed]           # single opponent battle"
    puts "  ruby battle.rb <str> <agi> <con> --simulate   # player vs tournament"
    puts "  ruby battle.rb <str> <agi> <con> [seed]       # single tournament run"
    puts ""
    puts "Opponents: #{OPPONENT_NAMES.join(', ')}"
    puts "Player budget: #{PLAYER_POINTS} points (str + agi + con = #{PLAYER_POINTS}, min 1 each)"
    exit 1
  end

  if OPPONENT_NAMES.include?(ARGV[0])
    # Opponent vs opponent mode
    name_a, name_b = ARGV[0], ARGV[1]
    raise "Unknown opponent: #{name_b}" unless OPPONENT_NAMES.include?(name_b)
    char_a = OPPONENTS[name_a]
    char_b = OPPONENTS[name_b]
    if ARGV.include?('--simulate')
      puts JSON.pretty_generate(simulate_matchup(char_a, char_b))
    else
      seed = ARGV[2]&.to_i || 42
      puts JSON.pretty_generate(single_battle(char_a, char_b, seed: seed))
    end
  else
    # Player vs tournament mode
    s, a, c = ARGV[0].to_i, ARGV[1].to_i, ARGV[2].to_i
    player = make_character(str: s, agi: a, con: c)
    if ARGV.include?('--simulate')
      puts JSON.pretty_generate(simulate_tournament(player))
    else
      seed = ARGV[3]&.to_i || 42
      puts JSON.pretty_generate(tournament(player, seed: seed))
    end
  end
end
