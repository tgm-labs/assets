### 1. Users Table
```sql
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- User ID, using UUID as the primary key
    telegram_id VARCHAR(50) NOT NULL UNIQUE, -- User's Telegram ID, unique
    username VARCHAR(50), -- Username
    first_name VARCHAR(100), -- User's first name
    last_name VARCHAR(100), -- User's last name
    country VARCHAR(50), -- User's country
    profile_picture_url VARCHAR(255), -- URL of user's profile picture
    wagering_multiplier INT DEFAULT 10, -- Default wagering multiplier, adjustable as needed
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Account creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last update time
    last_login TIMESTAMP NULL, -- Last login time
    last_login_ip VARCHAR(45), -- Last login IP address (supports IPv4/IPv6)
    status ENUM('active', 'inactive', 'banned') DEFAULT 'active', -- Account status (active, inactive, banned)
    referral_code VARCHAR(50), -- Referral code
    referred_by UUID, -- Referrer ID (foreign key)
    FOREIGN KEY (referred_by) REFERENCES users(user_id) -- Foreign key referencing the user ID in the users table
);
```

### 2. User Activity Logs Table
```sql
CREATE TABLE user_activity_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY, -- Unique ID for the activity log
    user_id UUID, -- User ID (foreign key)
    activity_type ENUM('login', 'logout', 'bet', 'transaction', 'other') NOT NULL, -- Type of activity
    activity_details TEXT, -- Details of the activity
    activity_ip VARCHAR(45), -- IP address of the activity (supports IPv4/IPv6)
    activity_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Time of the activity
    FOREIGN KEY (user_id) REFERENCES users(user_id) -- Foreign key referencing the user ID in the users table
);
```

### 3. Game Categories Table
```sql
CREATE TABLE game_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY, -- Unique ID for the game category
    category_name VARCHAR(50) NOT NULL UNIQUE, -- Name of the game category, unique
    description TEXT -- Description of the game category
);
```

### 4. Providers Table
```sql
CREATE TABLE providers (
    provider_id INT AUTO_INCREMENT PRIMARY KEY, -- Unique ID for the provider
    provider_name VARCHAR(100) NOT NULL UNIQUE, -- Name of the provider, unique
    api_url VARCHAR(255) NOT NULL, -- API URL
    description TEXT -- Description of the provider
);
```

### 5. Games Table
```sql
CREATE TABLE games (
    game_id INT AUTO_INCREMENT PRIMARY KEY, -- Unique ID for the game
    name VARCHAR(100) NOT NULL, -- Name of the game
    description TEXT, -- Description of the game
    category_id INT, -- Foreign key to game category
    provider_id INT, -- Foreign key to provider
    api_game_id VARCHAR(100) NOT NULL, -- API game ID
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last update time
    FOREIGN KEY (category_id) REFERENCES game_categories(category_id), -- Foreign key referencing the game category
    FOREIGN KEY (provider_id) REFERENCES providers(provider_id) -- Foreign key referencing the provider
);
```

### 6. Bets Table
```sql
CREATE TABLE bets (
    bet_id INT PRIMARY KEY AUTO_INCREMENT, -- Unique ID for the bet
    user_id UUID, -- User ID (foreign key)
    game_id INT, -- Game ID (foreign key)
    bet_amount DECIMAL(18, 8), -- Amount of the bet
    currency_id INT, -- Currency ID (foreign key)
    bet_result ENUM('win', 'lose', 'pending'), -- Result of the bet (win, lose, pending)
    win_amount DECIMAL(18, 8) DEFAULT 0.0, -- Amount won
    bet_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Time of the bet
    FOREIGN KEY (user_id) REFERENCES users(user_id), -- Foreign key referencing the user ID in the users table
    FOREIGN KEY (game_id) REFERENCES games(game_id), -- Foreign key referencing the game ID in the games table
    FOREIGN KEY (currency_id) REFERENCES currencies(currency_id) -- Foreign key referencing the currency ID
);
```

### 7. Transactions Table
```sql
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT, -- Unique ID for the transaction
    user_id UUID, -- User ID (foreign key)
    currency_id INT, -- Currency ID (foreign key)
    transaction_type ENUM('deposit', 'withdrawal'), -- Type of transaction (deposit, withdrawal)
    amount DECIMAL(18, 8), -- Amount of the transaction
    status ENUM('pending', 'completed', 'failed') DEFAULT 'pending', -- Status of the transaction (pending, completed, failed)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Creation time
    FOREIGN KEY (user_id) REFERENCES users(user_id), -- Foreign key referencing the user ID in the users table
    FOREIGN KEY (currency_id) REFERENCES currencies(currency_id) -- Foreign key referencing the currency ID
);
```

### 8. Game Results Table
```sql
CREATE TABLE game_results (
    result_id INT AUTO_INCREMENT PRIMARY KEY, -- Unique ID for the game result
    game_id INT, -- Game ID (foreign key)
    user_id UUID, -- User ID (foreign key)
    result_details TEXT, -- Details of the game result
    api_result_id VARCHAR(100), -- API result ID
    result_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Time of the result
    FOREIGN KEY (game_id) REFERENCES games(game_id), -- Foreign key referencing the game ID in the games table
    FOREIGN KEY (user_id) REFERENCES users(user_id) -- Foreign key referencing the user ID in the users table
);
```

### 9. Wallets Table
```sql
CREATE TABLE wallets (
    wallet_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- Wallet ID, using UUID as the primary key
    user_id UUID, -- User ID (foreign key)
    currency_id INT, -- Currency ID (foreign key)
    address VARCHAR(255) NOT NULL, -- Wallet address
    balance DECIMAL(18, 8) DEFAULT 0.0, -- Wallet balance
    priority INT DEFAULT 0, -- Payment priority, lower values indicate higher priority
    FOREIGN KEY (user_id) REFERENCES users(user_id), -- Foreign key referencing the user ID in the users table
    FOREIGN KEY (currency_id) REFERENCES currencies(currency_id) -- Foreign key referencing the currency ID
);
```

### 10. Referral Logs Table
```sql
CREATE TABLE referral_logs (
    referral_id INT AUTO_INCREMENT PRIMARY KEY, -- Unique ID for the referral log
    referrer_id UUID, -- Referrer's user ID (foreign key)
    referee_id UUID, -- Referee's user ID (foreign key)
    referral_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Time of referral
    referral_type ENUM('link', 'qrcode', 'social_media', 'other') DEFAULT 'link', -- Type of referral
    FOREIGN KEY (referrer_id) REFERENCES users(user_id), -- Foreign key referencing the referrer ID in the users table
    FOREIGN KEY (referee_id) REFERENCES users(user_id) -- Foreign key referencing the referee ID in the users table
);
```

### 11. Cashback Records Table
```sql
CREATE TABLE cashback_records (
    cashback_id INT AUTO_INCREMENT PRIMARY KEY, -- Unique ID for the cashback record
    user_id UUID, -- User ID (foreign key)
    amount DECIMAL(18, 8) NOT NULL, -- Cashback amount
    cashback_type ENUM('loss', 'bet', 'win') NOT NULL, -- Type of cashback (loss-based, bet-based, win-based)
    period_start DATE, -- Start date of the cashback calculation period
    period_end DATE, -- End date of the cashback calculation period
    status ENUM('pending', 'completed') DEFAULT 'pending', -- Status of the cashback record (pending, completed)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Last update time
    FOREIGN KEY (user_id) REFERENCES users(user_id) -- Foreign key referencing the user ID in the users table
);
```

### 12. Cashback Settings Table
```sql
CREATE TABLE cashback_settings (
    setting_id INT AUTO_INCREMENT PRIMARY KEY, -- Unique ID for the cashback setting
    cashback_type ENUM('loss', 'bet', 'win') NOT NULL, -- Type of cashback (loss-based, bet-based, win-based)
    cycle ENUM('daily', 'weekly', 'monthly') NOT NULL, -- Cashback cycle (daily, weekly, monthly)
    percentage DECIMAL(5, 2) NOT NULL, -- Cashback percentage, e.g., 5.00 for 5%
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP -- Last update time
);
```

### 13.Currencies Table
```sql
CREATE TABLE currencies (
    currency_id INT AUTO_INCREMENT PRIMARY KEY, -- Unique ID for the currency
    currency_name VARCHAR(50) NOT NULL, -- Name of the currency
    symbol VARCHAR(10) NOT NULL, -- Symbol of the currency (e.g., USD, BTC)
    type ENUM('ERC20', 'TRC20', 'BTC', 'BSC', 'Other') NOT NULL, -- Type of the currency (e.g., ERC20 token, TRC20 token, Bitcoin, Binance Smart Chain, Other)
    contract_address VARCHAR(255), -- Contract address for tokens (e.g., ERC20, TRC20)
    decimal_places INT NOT NULL, -- Number of decimal places for the currency
    icon_url VARCHAR(255) -- URL of the currency's icon
);
```

**Explanation**:
- **Users Table**: Stores user information, including personal details, referral codes, and statuses. It also tracks the referral relationship between users.
- **User Activity Logs Table**: Keeps records of user activities like logins, bets, and transactions for audit and tracking purposes.
- **Game Categories Table**: Defines different categories of games.
- **Providers Table**: Contains information about game providers and their API URLs.
- **Games Table**: Stores information about individual games, including their categories and providers.
- **Bets Table**: Logs betting activities, including the amounts bet and the results.
- **Transactions Table**: Tracks financial transactions such as deposits and withdrawals.
- **Game Results Table**: Records the outcomes of games.
- **Wallets Table**: Manages user wallets, including balance and priority for payments.
- **Referral Logs Table**: Records referral activities, capturing who referred whom and the method of referral.
- **Cashback Records Table**: Keeps track of cashback transactions, including the type and status.
- **Cashback Settings Table**: Defines cashback settings, including type, cycle, and percentage.
- **Currencies Table**:Stores information about different currencies, including their names, symbols, types, and contract addresses.