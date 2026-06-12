# Ruby Battle Engine

A turn-based battle simulator for character-building challenges.

## Stats

- **Strength (STR)** — damage dealt per round
- **Agility (AGI)** — damage reduction (0.5 per point)
- **Constitution (CON)** — hit points (20 per point)

## Mechanics

- Both characters attack simultaneously each round
- Damage = attacker STR − defender AGI×0.5 ± 1 (random variance, min 0)
- First to 0 HP loses; if simultaneous, higher remaining HP wins
- Battle ends after 300 rounds (compare remaining HP)

## Tournament Mode

A tournament brackets the first N opponents (sorted by level) in a random order
determined by the seed. HP carries over between fights — surviving HP from one
fight is your starting HP for the next.

- The player must win **all** fights to win the tournament
- Bracket order is randomized per seed
- Level N tournament = fight opponents of level 1 through N

## Leveling

Characters gain points per level:
- Level 1: 13 points total (starting_points=3 + points_per_level=10 × 1)
- Level 2: 23 points
- Level 3: 33 points
- Level 4: 43 points

Minimum 1 point per stat.

## Usage

```bash
# Single battle (two characters by stats)
ruby battle.rb <str_a> <agi_a> <con_a> <str_b> <agi_b> <con_b> [seed]

# Simulate 100 single battles
ruby battle.rb <str_a> <agi_a> <con_a> <str_b> <agi_b> <con_b> --simulate

# Single tournament run (level 4 bracket, seed 42)
ruby battle.rb <str_a> <agi_a> <con_a> --tournament --level N [seed]

# Simulate 100 tournament seeds
ruby battle.rb <str_a> <agi_a> <con_a> --tournament --level N --simulate
```

## Opponents (characters.json)

| Name | Level | STR | AGI | CON | Notes |
|------|-------|-----|-----|-----|-------|
| Goblin | 1 | 3 | 1 | 4 | Weak, low DR |
| Iron Golem | 2 | 5 | 8 | 4 | Very high DR (4.0) — needs STR > 4 to deal damage |
| Berserker | 3 | 12 | 2 | 6 | Massive damage output |
| Champion | 4 | 9 | 5 | 10 | Balanced, high HP |
