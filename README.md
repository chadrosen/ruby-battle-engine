# Ruby Battle Engine

A simple turn-based battle simulator for character-building challenges.

## Stats

- **Strength** — damage dealt per round
- **Agility** — damage reduction (0.5 per point)
- **Constitution** — hit points (20 per point)

## Mechanics

- Both characters attack simultaneously each round
- Damage = attacker STR − defender AGI×0.5 ± 1 (random variance, min 0)
- First to 0 HP loses; if simultaneous, higher remaining HP wins
- Battle ends after 300 rounds (compare remaining HP)

## Usage

```bash
# Single battle
ruby battle.rb <str_a> <agi_a> <con_a> <str_b> <agi_b> <con_b> [seed]

# Simulate 100 battles
ruby battle.rb <str_a> <agi_a> <con_a> <str_b> <agi_b> <con_b> --simulate
```

## Leveling

Characters start with 1 point in each stat (3 total) and gain 10 points per level:
- Level 1: 13 points to allocate
- Level 2: 23 points
- Level 3: 33 points
