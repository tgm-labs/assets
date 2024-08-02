### 1. Users Table
```sql
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,  -- User's unique ID
    telegram_id BIGINT NOT NULL UNIQUE,      -- User's Telegram ID
    username VARCHAR(50),                    -- User's username
    first_name VARCHAR(100),                 -- User's first name
    last_name VARCHAR(100),                  -- User's last name
    country VARCHAR(50),                     -- User's country
    profile_picture_url VARCHAR(255),        -- URL to the user's profile picture
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Account creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Last update time
    last_login TIMESTAMP NULL,               -- Last login time
    status ENUM('active', 'inactive', 'banned') DEFAULT 'active',  -- Account status
    balance DECIMAL(18, 8) DEFAULT 0.0,      -- User's balance
    referral_code VARCHAR(50),               -- Referral code
    referred_by INT,                         -- Referrer ID
    FOREIGN KEY (referred_by) REFERENCES users(user_id)  -- Foreign key to referrer
);
```

### 2. Game Categories Table
```sql
CREATE TABLE game_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,  -- Game category's unique ID
    category_name VARCHAR(50) NOT NULL UNIQUE,   -- Game category name
    description TEXT                             -- Game category description
);
```

### 3. Providers Table
```sql
CREATE TABLE providers (
    provider_id INT AUTO_INCREMENT PRIMARY KEY,  -- Provider's unique ID
    provider_name VARCHAR(100) NOT NULL UNIQUE,  -- Provider name
    api_url VARCHAR(255) NOT NULL,               -- API URL
    description TEXT                             -- Provider description
);
```

### 4. Games Table
```sql
CREATE TABLE games (
    game_id INT AUTO_INCREMENT PRIMARY KEY,  -- Game's unique ID
    name VARCHAR(100) NOT NULL,              -- Game name
    description TEXT,                        -- Game description
    category_id INT,                         -- Foreign key to game category
    provider_id INT,                         -- Foreign key to provider
    api_game_id VARCHAR(100) NOT NULL,       -- API game ID
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Last update time
    FOREIGN KEY (category_id) REFERENCES game_categories(category_id),  -- Foreign key to game category
    FOREIGN KEY (provider_id) REFERENCES providers(provider_id)  -- Foreign key to provider
);
```

### 5. Bets Table
```sql
CREATE TABLE bets (
    bet_id INT AUTO_INCREMENT PRIMARY KEY,  -- Bet's unique ID
    user_id INT,                            -- Foreign key to user
    game_id INT,                            -- Foreign key to game
    bet_amount DECIMAL(10, 2) NOT NULL,     -- Bet amount
    payout_amount DECIMAL(10, 2),           -- Payout amount
    api_bet_id VARCHAR(100),                -- API bet ID
    bet_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Bet time
    FOREIGN KEY (user_id) REFERENCES users(user_id),  -- Foreign key to user
    FOREIGN KEY (game_id) REFERENCES games(game_id)  -- Foreign key to game
);
```

### 6. Transactions Table
```sql
CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,  -- Transaction's unique ID
    user_id INT,                                    -- Foreign key to user
    amount DECIMAL(18, 8) NOT NULL,                 -- Transaction amount
    transaction_type ENUM('deposit', 'withdrawal') NOT NULL,  -- Transaction type
    transaction_status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',  -- Transaction status
    transaction_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Transaction time
    wallet_id INT,                                   -- Foreign key to wallet
    source VARCHAR(100),                             -- Transaction source
    description TEXT,                                -- Transaction description
    FOREIGN KEY (user_id) REFERENCES users(user_id),  -- Foreign key to user
    FOREIGN KEY (wallet_id) REFERENCES wallets(wallet_id)  -- Foreign key to wallet
);
```

### 7. Game Results Table
```sql
CREATE TABLE game_results (
    result_id INT AUTO_INCREMENT PRIMARY KEY,  -- Game result's unique ID
    game_id INT,                               -- Foreign key to game
    user_id INT,                               -- Foreign key to user
    result_details TEXT,                       -- Game result details
    api_result_id VARCHAR(100),                -- API result ID
    result_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Result time
    FOREIGN KEY (game_id) REFERENCES games(game_id),  -- Foreign key to game
    FOREIGN KEY (user_id) REFERENCES users(user_id)  -- Foreign key to user
);
```

### 8. User Activity Logs Table
```sql
CREATE TABLE user_activity_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,  -- Activity log's unique ID
    user_id INT,                            -- Foreign key to user
    activity_type ENUM('login', 'logout', 'bet', 'payment', 'other') NOT NULL,  -- Activity type
    activity_details TEXT,                  -- Activity details
    activity_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Activity time
    FOREIGN KEY (user_id) REFERENCES users(user_id)  -- Foreign key to user
);
```

### 9. Wallets Table
```sql
CREATE TABLE wallets (
    wallet_id INT AUTO_INCREMENT PRIMARY KEY,  -- Wallet's unique ID
    user_id INT,                               -- Foreign key to user
    currency_code VARCHAR(10) NOT NULL,        -- Cryptocurrency code
    currency_name VARCHAR(50) NOT NULL,        -- Cryptocurrency name
    wallet_address VARCHAR(255) NOT NULL UNIQUE,  -- Wallet address
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Creation time
    FOREIGN KEY (user_id) REFERENCES users(user_id)  -- Foreign key to user
);
```

### 10. ICO Management Table
```sql
CREATE TABLE icos (
    ico_id INT AUTO_INCREMENT PRIMARY KEY,  -- ICO's unique ID
    ico_name VARCHAR(100) NOT NULL,         -- ICO name
    description TEXT,                       -- ICO description
    start_date TIMESTAMP NOT NULL,          -- ICO start date
    end_date TIMESTAMP NOT NULL,            -- ICO end date
    token_name VARCHAR(50) NOT NULL,        -- Token name
    token_symbol VARCHAR(10) NOT NULL,      -- Token symbol
    total_supply DECIMAL(18, 8) NOT NULL,   -- Total supply of tokens
    price_per_token DECIMAL(18, 8) NOT NULL,  -- Price per token
    soft_cap DECIMAL(18, 8) NOT NULL,       -- Soft cap
    hard_cap DECIMAL(18, 8) NOT NULL,       -- Hard cap
    status ENUM('active', 'completed', 'canceled') DEFAULT 'active',  -- ICO status
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP  -- Last update time
);
```

### 11. ICO Participants Table
```sql
CREATE TABLE ico_participants (
    participant_id INT AUTO_INCREMENT PRIMARY KEY,  -- Participant's unique ID
    ico_id INT,                                     -- Foreign key to ICO
    user_id INT,                                    -- Foreign key to user
    amount DECIMAL(18, 8) NOT NULL,                 -- Amount invested
    token_amount DECIMAL(18, 8) NOT NULL,           -- Amount of tokens received
    purchase_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Purchase time
    FOREIGN KEY (ico_id) REFERENCES icos(ico_id),   -- Foreign key to ICO
    FOREIGN KEY (user_id) REFERENCES users(user_id)  -- Foreign key to user
);
```

### 12. Token Sales Table
```sql
CREATE TABLE token_sales (
    sale_id INT AUTO_INCREMENT PRIMARY KEY,  -- Token sale's unique ID
    ico_id INT,                              -- Foreign key to ICO
    sale_amount DECIMAL(18, 8) NOT NULL,     -- Sale amount
    sale_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Sale time
    FOREIGN KEY (ico_id) REFERENCES icos(ico_id)  -- Foreign key to ICO
);
```

### 13. Airdrops Table
```sql
CREATE TABLE airdrops (
    airdrop_id INT AUTO_INCREMENT PRIMARY KEY,  -- Airdrop's unique ID
    airdrop_name VARCHAR(100) NOT NULL,         -- Airdrop name
    description TEXT,                           -- Airdrop description
    start_date TIMESTAMP NOT NULL,              -- Airdrop start date
    end_date TIMESTAMP NOT NULL,                -- Airdrop end date
    token_name VARCHAR(50) NOT NULL,            -- Token name
    token_symbol VARCHAR(10) NOT NULL,          -- Token symbol
    total_tokens DECIMAL(18, 8) NOT NULL,       -- Total tokens for airdrop
    airdrop_type ENUM('manual', 'automatic') DEFAULT 'automatic',  -- Airdrop type
    status ENUM('active', 'completed', 'canceled') DEFAULT 'active',  -- Airdrop status
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Creation time
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP 

 -- Last update time
);
```

### 14. Airdrop Participants Table
```sql
CREATE TABLE airdrop_participants (
    participant_id INT AUTO_INCREMENT PRIMARY KEY,  -- Participant's unique ID
    airdrop_id INT,                                 -- Foreign key to airdrop
    user_id INT,                                    -- Foreign key to user
    token_amount DECIMAL(18, 8) NOT NULL,           -- Amount of tokens received
    claim_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Claim time
    FOREIGN KEY (airdrop_id) REFERENCES airdrops(airdrop_id),  -- Foreign key to airdrop
    FOREIGN KEY (user_id) REFERENCES users(user_id)  -- Foreign key to user
);
```

### 15. Referral Logs Table
```sql
CREATE TABLE referral_logs (
    referral_id INT AUTO_INCREMENT PRIMARY KEY,  -- Referral log's unique ID
    referrer_id INT,                             -- Referrer's user ID
    referee_id INT,                              -- Referee's user ID
    referral_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Referral time
    referral_type ENUM('link', 'qrcode', 'social_media', 'other') DEFAULT 'link',  -- Referral type
    FOREIGN KEY (referrer_id) REFERENCES users(user_id),  -- Foreign key to referrer
    FOREIGN KEY (referee_id) REFERENCES users(user_id)  -- Foreign key to referee
);
```