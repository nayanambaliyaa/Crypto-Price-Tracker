select * from crypto;

-- 1. Relative Strength index(Rsi) Caculation
-- insight : kaya coin ka price artificial hype ki wajah se upper gaya hai?
-- rsi ks use coin overbought hai ya oversold

SELECT 
    [month], 
    coin_name, 
    rsi_14, 
    [close],
    CASE 
        WHEN rsi_14 >= 70 THEN 'Overbought (Sell Signal)'
        WHEN rsi_14 <= 30 THEN 'Oversold (Buy Signal)'
        ELSE 'Neutral'
    END AS rsi_status,
  
    CASE 
        WHEN [close] > ma_50 THEN 'Bullish Trend' 
        ELSE 'Bearish Trend' 
    END AS trend_regime
FROM crypto
WHERE [month] = (SELECT MAX([month]) FROM crypto);


-- 2. Consecutive Red/Green Days
-- konsa coin kitne dino se lagater gir raha he ya badh raha he

WITH StreakData AS (
    SELECT 
        month, 
        coin_name, 
        monthly_return,
        CASE WHEN monthly_return > 0 THEN 1 ELSE 0 END AS is_positive,
        LAG(CASE WHEN monthly_return > 0 THEN 1 ELSE 0 END) OVER (PARTITION BY coin_name ORDER BY month) AS prev_positive
    FROM crypto
)
SELECT 
    coin_name, 
    COUNT(*) AS consecutive_months,
    CASE WHEN is_positive = 1 THEN 'Green Streak' ELSE 'Red Streak' END AS streak_type
FROM StreakData
WHERE is_positive = prev_positive
GROUP BY coin_name, is_positive;



--3. Historical Volatility
-- last 30 days standard deviation 
-- risk management ke liye best konsa coin sabse unstable he

SELECT 
    coin_name, 
    AVG(volatility_30d) AS avg_monthly_volatility,
    MAX(max_drawdown) AS deepest_crash,
    RANK() OVER (ORDER BY AVG(volatility_30d) DESC) AS risk_rank
FROM crypto
GROUP BY coin_name
ORDER BY risk_rank;


--4. Profit and loss Distribution
-- 6 month before invest any coin to aj uska p&L kitna hota 
-- long-term holding vs short-term trading 

SELECT 
    coin_name,
    month,
    drawdown_from_ath,
    CASE 
        WHEN drawdown_from_ath < -80 THEN 'Extreme Loss (>80%)'
        WHEN drawdown_from_ath BETWEEN -80 AND -50 THEN 'Significant Correction'
        WHEN drawdown_from_ath BETWEEN -50 AND -10 THEN 'Moderate Dip'
        ELSE 'Near ATH'
    END AS recovery_status,
    news_sentiment 
FROM crypto
WHERE drawdown_from_ath IS NOT NULL
ORDER BY month DESC;