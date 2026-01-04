# 💊 KapSellDrugs - Enhanced Drug Selling System

A complete rewrite of the drug selling script with improved security, performance, and features.

---

## 🎯 What Changed

### Security Improvements
- ✅ **Transaction validation system** - Prevents exploits and duplication
- ✅ **Server-side validation** - All inventory checks happen server-side
- ✅ **Anti-replay protection** - Transactions expire after 60 seconds
- ✅ **Admin permission checks** - Secure admin commands

### Performance Improvements
- ✅ **Optimized client loops** - Dynamic wait times based on distance
- ✅ **Better entity cleanup** - Prevents memory leaks
- ✅ **Efficient database queries** - Uses async operations properly
- ✅ **Transaction cleanup thread** - Removes old pending transactions

### New Features
- ✅ **Multi-drug support** - Automatically detects which drug player has
- ✅ **Sale cooldown system** - Prevents spam (configurable)
- ✅ **Rejection chance** - Buyers sometimes get cold feet
- ✅ **Police alert system** - Random alerts with increasing chance per level
- ✅ **Total sales tracking** - Database tracks total completed sales
- ✅ **Admin commands** - Reset stats or set levels
- ✅ **Better notifications** - More informative with titles and icons
- ✅ **Level-up messages** - Shows new bonus when leveling

---

## 📦 Installation

### 1. Dependencies
Ensure you have these resources installed and started **BEFORE** this script:
- `ox_lib`
- `ox_inventory`
- `oxmysql`

### 2. Database
Run the SQL query from `sql.txt` in your database:
```sql
CREATE TABLE IF NOT EXISTS `player_drug_stats` (...)
```

### 3. Resource Setup
1. Place the folder in your `resources` directory
2. Add to your `server.cfg`:
```cfg
ensure KapSellDrugs
```

### 4. Configure Your Drugs
Edit `config.lua` and add your drug items:
```lua
Config.Drugs = {
    ["your_drug_item"] = { 
        label = "Drug Name", 
        minPrice = 50, 
        maxPrice = 100,
        minAmount = 1, 
        maxAmount = 5
    },
}
```

---

## 🎮 Commands

### Player Commands
- `/selldrugs` - Start selling drugs
- `/dealerstats` - Check your level, XP, and stats

### Admin Commands (Requires `admin` ace permission)
- `/resetdealerstats [playerID]` - Reset a player's stats
- `/setdealerlevel [playerID] [level]` - Set a player's level

To give admin permissions, add to your `server.cfg`:
```cfg
add_ace group.admin command.resetdealerstats allow
add_ace group.admin command.setdealerlevel allow
```

---

## ⚙️ Configuration

### Basic Settings
```lua
Config.Command = "selldrugs"          -- Command to sell
Config.SaleCooldown = 30000           -- 30 sec cooldown between sales
Config.SellTime = 8000                -- 8 sec base transaction time
Config.SpawnDistance = 15.0           -- How far buyer spawns
Config.RejectionChance = 0.15         -- 15% buyer rejection chance
```

### Leveling System
```lua
Config.XPPerSale = 1                  -- Flat XP per sale
Config.XPNeeded = 100                 -- XP to level up
Config.LevelSpeedsUpSales = true      -- Faster sales at higher levels
Config.SpeedBonusPerLevel = 150       -- 150ms faster per level
```

### Police Alerts
```lua
Config.PoliceAlertEnabled = true      -- Enable alerts
Config.BasePoliceAlertChance = 0.05   -- 5% base chance
Config.AlertChancePerLevel = 0.005    -- +0.5% per level
```

### Price Bonuses
Configure bonuses per level in `Config.LevelRewards`:
```lua
[1]  = 0.00,   -- No bonus
[5]  = 0.25,   -- +25%
[10] = 0.60,   -- +60%
[20] = 1.40,   -- +140%
[30] = 3.00,   -- +300%
```

---

## 🔗 Police Integration

The script includes a police alert system. To integrate with your police dispatch:

Edit `server.lua` around line 184:
```lua
if math.random() < alertChance then
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    
    -- Replace this with your police system trigger
    TriggerEvent('police:drugSaleAlert', playerCoords, src)
    -- Or: exports['your-dispatch']:DrugSale(playerCoords)
end
```

---

## 🐛 Troubleshooting

### "No drugs to sell"
- Make sure your drug item names in `Config.Drugs` match your inventory items exactly
- Check that you actually have the items in your inventory

### Ped won't spawn
- Check console for model loading errors
- Ensure `ox_lib` is running
- Verify ped models exist in `Config.PedModels`

### Stats not saving
- Verify `oxmysql` is running
- Check your database connection in `server.cfg`
- Look for SQL errors in server console

### Cooldown not working
- Check `Config.SaleCooldown` value (in milliseconds)
- 30000 = 30 seconds

---

## 📊 Database Schema

The script tracks:
- `identifier` - Player license
- `level` - Current dealer level
- `xp` - Experience points
- `total_sales` - Total completed transactions
- `created_at` - First sale timestamp
- `updated_at` - Last activity timestamp

A leaderboard view is also created for easy top dealer queries.

---

## 🎨 Customization Ideas

### Change Animation
Edit `client.lua` line 111-112:
```lua
local animDict = "mp_common"
local animName = "givetake1_a"
```

Try these alternatives:
- `"mp_common"` / `"givetake2_a"` - Different handoff
- `"mp_common_heist"` / `"cash_transfer"` - Money exchange
- `"mp_ped_interaction"` / `"handshake_guy_a"` - Handshake

### Add Sound Effects
Add after successful sale in `client.lua`:
```lua
PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
```

### Different Peds by Area
Replace random ped selection with location-based:
```lua
local playerCoords = GetEntityCoords(playerPed)
local model
if playerCoords.x > 0 then
    model = GetHashKey("a_m_m_business_01") -- Rich area
else
    model = GetHashKey("a_m_y_downtown_01") -- Poor area
end
```

---

## 📝 Credits

**Original Script:** Kap  
**Rewrite & Enhancement:** Claude (with your feedback!)

---

## 📄 License

Free to use and modify for your FiveM server.  
Credit appreciated but not required.

---

## 🤝 Support

Having issues? Check:
1. All dependencies are installed and started
2. Database table was created successfully
3. Drug item names match your inventory
4. Console for any error messages

Still stuck? Review the code comments - they explain what each section does!