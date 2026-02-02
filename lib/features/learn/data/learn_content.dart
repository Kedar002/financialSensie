// Hardcoded finance knowledge content
// Based on Knowledge Basket Finance Handbook

class LearnLevel {
  final String id;
  final String title;
  final String subtitle;
  final List<LearnLesson> lessons;

  const LearnLevel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.lessons,
  });
}

class LearnLesson {
  final String id;
  final String title;
  final String readTime;
  final List<LessonSection> sections;

  const LearnLesson({
    required this.id,
    required this.title,
    required this.readTime,
    required this.sections,
  });
}

class LessonSection {
  final String? heading;
  final String content;
  final List<String>? bullets;

  const LessonSection({
    this.heading,
    required this.content,
    this.bullets,
  });
}

const List<LearnLevel> learnLevels = [
  // LEVEL 1: FOUNDATION
  LearnLevel(
    id: 'foundation',
    title: 'Foundation',
    subtitle: 'Build your base',
    lessons: [
      // Lesson 1.1: Money Basics
      LearnLesson(
        id: 'money-basics',
        title: 'Money Basics',
        readTime: '3 min',
        sections: [
          LessonSection(
            content: 'Money is a tool to store value, exchange value, and measure value. Personal finance is not about maximizing income, but about optimizing cash flow, risk, behavior, and long-term freedom.',
          ),
          LessonSection(
            heading: 'Core Principles',
            content: 'These four principles form the foundation of all financial success:',
            bullets: [
              'Spend less than you earn',
              'Build systems, not willpower',
              'Protect downside before chasing upside',
              'Time in the market beats timing the market',
            ],
          ),
          LessonSection(
            heading: 'The Mindset Shift',
            content: 'Most people think personal finance is about earning more. It\'s not. It\'s about keeping more of what you earn, protecting it from risks, and letting time do the heavy lifting through compounding.',
          ),
        ],
      ),
      // Lesson 1.2: Budgeting Frameworks
      LearnLesson(
        id: 'budgeting',
        title: 'Budgeting Frameworks',
        readTime: '4 min',
        sections: [
          LessonSection(
            content: 'Budgeting is allocation, not restriction. The goal is automation and clarity. A good budget should disappear from your daily life.',
          ),
          LessonSection(
            heading: '50-30-20 Rule',
            content: 'The simplest framework. Split your income into three buckets:',
            bullets: [
              '50% for Needs (rent, groceries, utilities)',
              '30% for Wants (dining, entertainment, shopping)',
              '20% for Savings (investments, emergency fund)',
            ],
          ),
          LessonSection(
            heading: 'Zero-Based Budgeting',
            content: 'Every rupee gets assigned a job. Income minus all allocations equals zero. This gives you complete control but requires more effort.',
          ),
          LessonSection(
            heading: 'Pay Yourself First',
            content: 'Flip the script: Savings before expenses. The moment salary hits your account, investments are automated. Spend what remains guilt-free.',
          ),
          LessonSection(
            heading: 'Anti-Budget',
            content: 'For those who hate tracking: Automate savings and investments on salary day. Spend the rest however you want. Simple but effective.',
          ),
          LessonSection(
            heading: 'Best Practice',
            content: 'Automate savings and investments on salary day. The best budget is one you don\'t have to think about.',
          ),
        ],
      ),
      // Lesson 1.3: Emergency Fund
      LearnLesson(
        id: 'emergency-fund',
        title: 'Emergency Fund & Insurance',
        readTime: '4 min',
        sections: [
          LessonSection(
            content: 'An emergency fund protects you from selling investments at the worst time. It\'s not about returns—it\'s about peace of mind.',
          ),
          LessonSection(
            heading: 'How Much to Keep',
            content: 'Your emergency fund size depends on income stability:',
            bullets: [
              '3 months expenses — stable salaried job',
              '6-12 months expenses — variable income or business',
            ],
          ),
          LessonSection(
            heading: 'Where to Keep It',
            content: 'Liquid funds or a high-yield savings account. Don\'t chase returns here. Accessibility matters more than growth.',
          ),
          LessonSection(
            heading: 'Insurance Hierarchy',
            content: 'Insurance is risk transfer, not investment. Buy these in order:',
            bullets: [
              'Health insurance (base plan + super top-up)',
              'Term life insurance (only if you have dependents)',
            ],
          ),
          LessonSection(
            heading: 'The Golden Rule',
            content: 'Never mix insurance with investments. ULIPs, endowment plans, and money-back policies are almost always bad deals. Keep insurance pure.',
          ),
        ],
      ),
      // Lesson 1.4: Debt Management
      LearnLesson(
        id: 'debt',
        title: 'Debt & Credit',
        readTime: '3 min',
        sections: [
          LessonSection(
            content: 'Debt is neither good nor bad. Its purpose and cost determine its value. Low-interest debt for productive purposes can accelerate wealth. High-interest consumer debt destroys it.',
          ),
          LessonSection(
            heading: 'Good Debt',
            content: 'Low-interest, productive debt:',
            bullets: [
              'Education loans (investment in earning potential)',
              'Business loans (generates returns)',
              'Home loans (builds asset, tax benefits)',
            ],
          ),
          LessonSection(
            heading: 'Bad Debt',
            content: 'High-interest consumption debt:',
            bullets: [
              'Credit card debt (18-40% interest)',
              'Buy Now Pay Later (BNPL)',
              'Personal loans for lifestyle',
            ],
          ),
          LessonSection(
            heading: 'Repayment Strategies',
            content: 'Two proven methods to eliminate debt:',
            bullets: [
              'Avalanche Method: Pay highest interest first. Mathematically optimal.',
              'Snowball Method: Pay smallest balance first. Psychologically effective.',
            ],
          ),
          LessonSection(
            heading: 'The Rule',
            content: 'If the interest rate is higher than what you can earn investing, pay off the debt first.',
          ),
        ],
      ),
      // Lesson 1.5: Credit Score
      LearnLesson(
        id: 'credit-score',
        title: 'Credit Score Mastery',
        readTime: '4 min',
        sections: [
          LessonSection(
            content: 'Your credit score is a measure of how likely you are to pay back borrowed money. It affects loan approvals, interest rates, and even rental applications.',
          ),
          LessonSection(
            heading: 'The Score Breakdown',
            content: 'Credit scores typically range from 300-900. What affects your score:',
            bullets: [
              'Payment History (35%) — Pay bills on time, every time',
              'Credit Utilization (30%) — Use less than 30% of your limit',
              'Credit History (15%) — Longer history is better',
              'Credit Mix (10%) — Variety of credit types',
              'New Credit (10%) — Too many new accounts hurts',
            ],
          ),
          LessonSection(
            heading: 'Building Good Credit',
            content: 'Practical steps to improve your score:',
            bullets: [
              'Pay full balance monthly — Never carry credit card debt',
              'Keep old cards open — Length of history matters',
              'Keep utilization low — High limits, low usage',
              'Limit hard inquiries — Don\'t apply for many cards at once',
            ],
          ),
          LessonSection(
            heading: 'Credit Card Reality',
            content: 'Credit cards are a double-edged sword. Used responsibly: rewards, convenience, credit building. Used poorly: 18-40% interest rates, debt spiral. The key? Always pay full balance. If you can\'t trust yourself, use a debit card.',
          ),
        ],
      ),
      // Lesson 1.6: Money Personality
      LearnLesson(
        id: 'money-personality',
        title: 'Know Your Money Type',
        readTime: '3 min',
        sections: [
          LessonSection(
            content: 'Understanding your natural relationship with money helps you build systems that work with your personality, not against it.',
          ),
          LessonSection(
            heading: 'The Spender',
            content: 'Lives in the moment, enjoys spending, may struggle with saving. Strength: Enjoys life. Challenge: Planning for future. Tip: Automate savings FIRST, then spend guilt-free.',
          ),
          LessonSection(
            heading: 'The Saver',
            content: 'Excellent at saving, frugal, goal-oriented. Strength: Financial discipline. Challenge: May neglect present enjoyment. Tip: Budget for guilt-free fun money.',
          ),
          LessonSection(
            heading: 'The Balancer',
            content: 'Good at managing money, makes smart decisions. Strength: Balance between saving and spending. Challenge: Can be indecisive, may miss opportunities. Tip: Trust your instincts more.',
          ),
          LessonSection(
            heading: 'The Investor',
            content: 'Strategic, seeks growth, willing to take risks. Strength: Wealth building mindset. Challenge: May ignore basics or take too much risk. Tip: Secure foundations before aggressive moves.',
          ),
        ],
      ),
      // Lesson 1.7: Banking Basics
      LearnLesson(
        id: 'banking-basics',
        title: 'Banking Basics',
        readTime: '3 min',
        sections: [
          LessonSection(
            content: 'Banks make money by paying you low interest on deposits while charging higher interest on loans. Understanding account types helps you optimize where your money sits.',
          ),
          LessonSection(
            heading: 'Account Types',
            content: 'Match the account to the purpose:',
            bullets: [
              'Savings Account — Emergency fund, short-term goals. Easy access, modest interest.',
              'Fixed Deposit (FD) — Lock money for higher interest. Penalty for early withdrawal.',
              'Recurring Deposit (RD) — Monthly fixed deposits. Good for building savings habit.',
              'Current Account — For business, high transactions. Usually no interest.',
            ],
          ),
          LessonSection(
            heading: 'Interest Rate Reality',
            content: 'Savings accounts typically pay 3-4% interest. Inflation is often 5-6%. Your money in savings is slowly losing purchasing power. That\'s why investing matters for long-term goals.',
          ),
          LessonSection(
            heading: 'Bank Selection',
            content: 'Consider: branch accessibility, digital banking quality, fees, and customer service. For most people, a reliable bank with good app is more important than chasing highest interest rates.',
          ),
        ],
      ),
    ],
  ),

  // LEVEL 2: WEALTH BUILDING
  LearnLevel(
    id: 'wealth-building',
    title: 'Wealth Building',
    subtitle: 'Grow your money',
    lessons: [
      // Lesson 2.1: Investing Fundamentals
      LearnLesson(
        id: 'investing-basics',
        title: 'Investing Fundamentals',
        readTime: '3 min',
        sections: [
          LessonSection(
            content: 'Investing is deploying capital today to receive more capital in the future, adjusted for risk. It\'s how you make money work for you instead of working for money.',
          ),
          LessonSection(
            heading: 'Key Concepts',
            content: 'Four ideas that govern all investing:',
            bullets: [
              'Risk vs Return — Higher potential returns = higher risk',
              'Compounding — Returns generate returns on themselves',
              'Real Returns — What matters is return after inflation',
              'Asset Allocation — More important than stock picking',
            ],
          ),
          LessonSection(
            heading: 'The Power of Compounding',
            content: 'Einstein allegedly called it the eighth wonder of the world. ₹1 lakh at 12% becomes ₹3 lakhs in 10 years, ₹10 lakhs in 20 years, and ₹30 lakhs in 30 years. Time is the multiplier.',
          ),
          LessonSection(
            heading: 'Start Now',
            content: 'The best time to start investing was 10 years ago. The second best time is now. Don\'t wait for the "right time"—time in the market beats timing the market.',
          ),
        ],
      ),
      // Lesson 2.2: Asset Classes
      LearnLesson(
        id: 'asset-classes',
        title: 'Asset Classes',
        readTime: '4 min',
        sections: [
          LessonSection(
            content: 'All investments fall into asset classes. Understanding each helps you build a balanced portfolio.',
          ),
          LessonSection(
            heading: 'Equity (Stocks)',
            content: 'Ownership in businesses. Highest long-term returns but high volatility. You\'re a part-owner of companies. Over 15+ years, equity has beaten all other asset classes in India.',
          ),
          LessonSection(
            heading: 'Debt (Bonds/FDs)',
            content: 'Loans to governments or companies. Lower returns but stable. You\'re a lender, not an owner. Good for capital preservation and regular income.',
          ),
          LessonSection(
            heading: 'Gold',
            content: 'Hedge against currency devaluation and crisis. Doesn\'t generate cash flow but preserves purchasing power. Good for 5-10% of portfolio.',
          ),
          LessonSection(
            heading: 'Real Estate',
            content: 'Illiquid, leverage-heavy, location dependent. Can build wealth but requires large capital and active management. Not as passive as people think.',
          ),
          LessonSection(
            heading: 'Cash',
            content: 'Liquidity buffer. Essential for emergencies but a return destroyer if held excessively. Inflation eats cash every year.',
          ),
          LessonSection(
            heading: 'The Mix',
            content: 'A simple allocation: 60-70% equity, 20-30% debt, 5-10% gold. Adjust based on age, goals, and risk tolerance.',
          ),
        ],
      ),
      // Lesson 2.3: Mutual Funds
      LearnLesson(
        id: 'mutual-funds',
        title: 'Mutual Funds & ETFs',
        readTime: '4 min',
        sections: [
          LessonSection(
            content: 'Mutual funds pool money from many investors to invest professionally. You get diversification and professional management without needing large capital.',
          ),
          LessonSection(
            heading: 'Types of Mutual Funds',
            content: 'Common categories you\'ll encounter:',
            bullets: [
              'Index Funds — Track an index like Nifty 50. Low cost, passive.',
              'Large Cap — Invest in top 100 companies. Stable.',
              'Mid/Small Cap — Higher growth potential, higher risk.',
              'Debt Funds — Invest in bonds. Lower risk than equity.',
              'Hybrid Funds — Mix of equity and debt.',
            ],
          ),
          LessonSection(
            heading: 'ETFs (Exchange Traded Funds)',
            content: 'Similar to index funds but trade like stocks on exchanges. Usually have even lower expense ratios. Good for lumpsum investing.',
          ),
          LessonSection(
            heading: 'Expense Ratio Matters',
            content: 'A 1% difference in expense ratio compounds massively over decades. Prefer direct plans over regular plans. Prefer low-cost index funds for most of your portfolio.',
          ),
          LessonSection(
            heading: 'Keep It Simple',
            content: 'You don\'t need 10 funds. A Nifty 50 index fund + a Nifty Next 50 fund can be your entire equity portfolio. Simplicity beats complexity.',
          ),
        ],
      ),
      // Lesson 2.4: SIP & Compounding
      LearnLesson(
        id: 'sip-compounding',
        title: 'SIP & Compounding',
        readTime: '3 min',
        sections: [
          LessonSection(
            content: 'Systematic Investment Plans (SIP) are the most powerful wealth-building tool for regular people. They reduce timing risk and enforce discipline.',
          ),
          LessonSection(
            heading: 'How SIP Works',
            content: 'You invest a fixed amount every month regardless of market conditions. When markets are down, you buy more units. When markets are up, you buy fewer. This averages out your cost over time.',
          ),
          LessonSection(
            heading: 'SIP vs Lumpsum',
            content: 'Both work. SIP is better for salaried people with regular income. Lumpsum works if you have a large amount and long time horizon. Don\'t overthink—just start.',
          ),
          LessonSection(
            heading: 'The Compounding Formula',
            content: 'Returns generate returns on themselves. ₹10,000/month SIP at 12% for 20 years = ₹1 crore. For 30 years = ₹3.5 crore. The last 10 years add more than the first 20.',
          ),
          LessonSection(
            heading: 'Time > Rate',
            content: 'Starting early beats investing aggressively later. Someone who starts at 25 with ₹5,000/month beats someone who starts at 35 with ₹15,000/month. Time is the cheat code.',
          ),
        ],
      ),
    ],
  ),

  // LEVEL 3: MARKET INTELLIGENCE
  LearnLevel(
    id: 'market-intelligence',
    title: 'Market Intelligence',
    subtitle: 'Understand markets',
    lessons: [
      // Lesson 3.1: Stock Market
      LearnLesson(
        id: 'stocks',
        title: 'Stock Market Basics',
        readTime: '4 min',
        sections: [
          LessonSection(
            content: 'Stocks represent fractional ownership in businesses. When you buy a stock, you become a part-owner of that company. Price fluctuates daily, but value compounds over years.',
          ),
          LessonSection(
            heading: 'Two Approaches',
            content: 'There are two ways to invest in stocks:',
            bullets: [
              'Active Investing — Stock picking based on research and valuation. Requires time and skill.',
              'Passive Investing — Index funds that buy the entire market. Low cost, diversified, beats most active investors.',
            ],
          ),
          LessonSection(
            heading: 'Valuation Basics',
            content: 'How to know if a stock is cheap or expensive:',
            bullets: [
              'PE Ratio — Price relative to earnings. Lower = cheaper.',
              'PB Ratio — Price relative to book value.',
              'ROE/ROCE — How efficiently company uses capital.',
              'Cash Flow — Actual money generated, not just accounting profit.',
            ],
          ),
          LessonSection(
            heading: 'For Most People',
            content: 'Unless you have genuine interest in studying businesses, index funds beat stock picking. Even professional fund managers struggle to beat the index consistently.',
          ),
        ],
      ),
      // Lesson 3.2: Behavioral Finance
      LearnLesson(
        id: 'behavior',
        title: 'Behavioral Finance',
        readTime: '4 min',
        sections: [
          LessonSection(
            content: 'Most investors fail not due to lack of knowledge, but due to behavior. Your brain is wired for survival, not investing. Understanding this is half the battle.',
          ),
          LessonSection(
            heading: 'Common Biases',
            content: 'Mental traps that hurt investors:',
            bullets: [
              'Loss Aversion — Losses hurt 2x more than gains feel good. Makes you sell winners and hold losers.',
              'Recency Bias — Overweighting recent events. Bull markets feel permanent. So do crashes.',
              'Overconfidence — Leads to excessive trading. More trades = more mistakes.',
              'Herd Mentality — Following the crowd into bubbles and panics.',
            ],
          ),
          LessonSection(
            heading: 'The Solution',
            content: 'Combat behavior with systems:',
            bullets: [
              'Automate investments — Remove emotion from the equation',
              'Have written rules — Decide in advance when to buy/sell',
              'Long-term thinking — Zoom out from daily noise',
              'Ignore news — 99% of financial news is irrelevant',
            ],
          ),
          LessonSection(
            heading: 'The Edge',
            content: 'Your biggest edge as a small investor is patience. Institutions can\'t afford to wait 10 years. You can. Use that advantage.',
          ),
        ],
      ),
      // Lesson 3.3: Market Cycles
      LearnLesson(
        id: 'cycles',
        title: 'Market Cycles',
        readTime: '3 min',
        sections: [
          LessonSection(
            content: 'Markets move in cycles driven by liquidity, earnings, and sentiment. Understanding this prevents panic during downturns and greed during rallies.',
          ),
          LessonSection(
            heading: 'Economic Indicators',
            content: 'What moves markets:',
            bullets: [
              'Interest Rates — Rising rates hurt valuations, falling rates support them',
              'Inflation — Moderate inflation is okay, high inflation erodes returns',
              'GDP Growth — Economic growth drives corporate earnings',
              'Employment — More jobs = more spending = more profits',
            ],
          ),
          LessonSection(
            heading: 'The Cycle Pattern',
            content: 'Markets typically cycle through: Recovery → Expansion → Peak → Recession → Recovery. Each phase has different characteristics. No one can time these perfectly.',
          ),
          LessonSection(
            heading: 'What To Do',
            content: 'Don\'t try to time cycles. Stay invested through all phases. If you must act, be greedy when others are fearful, and fearful when others are greedy.',
          ),
        ],
      ),
      // Lesson 3.4: Taxation
      LearnLesson(
        id: 'taxation',
        title: 'Taxation (India)',
        readTime: '3 min',
        sections: [
          LessonSection(
            content: 'Taxes materially affect your net returns. Understanding the basics helps you keep more of what you earn.',
          ),
          LessonSection(
            heading: 'Equity Taxation',
            content: 'Tax rates on stock/equity mutual fund gains:',
            bullets: [
              'LTCG (Long Term) — Holding > 1 year. Taxed above ₹1 lakh gains.',
              'STCG (Short Term) — Holding < 1 year. Higher tax rate.',
            ],
          ),
          LessonSection(
            heading: 'Debt Taxation',
            content: 'Debt mutual funds are now taxed at your income tax slab regardless of holding period. This changed in 2023.',
          ),
          LessonSection(
            heading: 'Tax Harvesting',
            content: 'Book losses to offset gains and reduce tax. Book gains up to ₹1 lakh every year tax-free. Small optimizations compound over decades.',
          ),
          LessonSection(
            heading: 'Don\'t Over-Optimize',
            content: 'Tax efficiency matters, but don\'t let tax tail wag the investment dog. A good investment with slightly higher tax beats a bad investment with tax benefits.',
          ),
        ],
      ),
    ],
  ),

  // LEVEL 4: PHILOSOPHY
  LearnLevel(
    id: 'philosophy',
    title: 'Philosophy',
    subtitle: 'The long game',
    lessons: [
      // Lesson 4.1: FIRE
      LearnLesson(
        id: 'fire',
        title: 'Financial Independence',
        readTime: '4 min',
        sections: [
          LessonSection(
            content: 'Financial Independence means your investments can fund your lifestyle without active work. It\'s not about retiring early—it\'s about having the choice.',
          ),
          LessonSection(
            heading: 'The FI Number',
            content: 'Your target = Annual expenses ÷ Safe withdrawal rate. If you spend ₹6 lakhs/year and use 4% withdrawal rate, your FI number is ₹1.5 crore.',
          ),
          LessonSection(
            heading: 'FIRE Variants',
            content: 'Different flavors of financial independence:',
            bullets: [
              'Lean FIRE — Minimal lifestyle, lower target, earlier freedom',
              'Fat FIRE — Comfortable lifestyle, higher target, later freedom',
              'Coast FIRE — Investments growing, only need to cover current expenses',
              'Barista FIRE — Part-time work for benefits, investments cover rest',
            ],
          ),
          LessonSection(
            heading: 'The Path',
            content: 'FIRE is simple math: Save aggressively, invest consistently, wait patiently. A 50% savings rate can get you to FI in 15-17 years regardless of income level.',
          ),
          LessonSection(
            heading: 'Beyond Money',
            content: 'FI is not the destination—it\'s the starting point. Know what you\'re retiring TO, not just what you\'re retiring FROM.',
          ),
        ],
      ),
      // Lesson 4.2: Systems
      LearnLesson(
        id: 'systems',
        title: 'Building Your System',
        readTime: '3 min',
        sections: [
          LessonSection(
            content: 'The best personal finance systems are boring, automated, and resilient. They work whether you\'re motivated or not, whether markets are up or down.',
          ),
          LessonSection(
            heading: 'The Flow',
            content: 'Design your money flow:',
            bullets: [
              'Income arrives → Auto-transfer to investments',
              'Investments → Low-cost diversified funds',
              'Remainder → Guilt-free spending',
            ],
          ),
          LessonSection(
            heading: 'Review Cadence',
            content: 'Annual review, not daily tracking. Check allocations once a year. Rebalance if needed. Otherwise, leave it alone.',
          ),
          LessonSection(
            heading: 'Keep It Simple',
            content: 'You don\'t need 15 accounts and 20 funds. One bank account, one brokerage, 2-3 funds. Complexity is the enemy of consistency.',
          ),
          LessonSection(
            heading: 'The Goal',
            content: 'Your system should run in the background while you live your life. If you\'re constantly thinking about money, your system isn\'t working.',
          ),
        ],
      ),
      // Lesson 4.3: Wealth Philosophy
      LearnLesson(
        id: 'wealth-philosophy',
        title: 'Wealth Philosophy',
        readTime: '3 min',
        sections: [
          LessonSection(
            content: 'Wealth is freedom, not consumption. The goal is not to buy more things—it\'s to buy time, optionality, and peace of mind.',
          ),
          LessonSection(
            heading: 'Avoid Lifestyle Inflation',
            content: 'As income grows, expenses shouldn\'t grow proportionally. The gap between income and expenses is what builds wealth, not income alone.',
          ),
          LessonSection(
            heading: 'What Money Buys',
            content: 'The best things money can buy:',
            bullets: [
              'Time — To do what matters to you',
              'Options — To say no to things you don\'t want',
              'Security — Peace of mind for your family',
              'Freedom — To take risks and explore',
            ],
          ),
          LessonSection(
            heading: 'The Goal',
            content: 'The goal is not to beat the market. The goal is to meet your life goals reliably. A 10% return that lets you sleep at night beats a 15% return that causes anxiety.',
          ),
          LessonSection(
            heading: 'Final Thought',
            content: 'Money is a tool to support your life, not the other way around. Build wealth in service of a life well-lived, not as a score to maximize.',
          ),
        ],
      ),
      // Lesson 4.4: Rent vs Buy
      LearnLesson(
        id: 'rent-vs-buy',
        title: 'Rent vs Buy Decision',
        readTime: '4 min',
        sections: [
          LessonSection(
            content: 'Buying a home is often treated as an automatic goal. But the math isn\'t always in favor of buying. It depends on your situation, location, and timeline.',
          ),
          LessonSection(
            heading: 'True Cost of Buying',
            content: 'Owning a home costs more than the EMI:',
            bullets: [
              'Down payment — 10-20% locked up, can\'t invest elsewhere',
              'EMI interest — Often 2-3x the principal over loan tenure',
              'Property tax — Annual recurring cost',
              'Maintenance — 1-2% of property value yearly',
              'Opportunity cost — What your down payment could earn invested',
            ],
          ),
          LessonSection(
            heading: 'When Renting Wins',
            content: 'Renting often makes more sense when:',
            bullets: [
              'You may relocate in 3-5 years',
              'Rent is significantly cheaper than EMI',
              'You can invest the difference and earn more',
              'Property prices are very high relative to rents',
            ],
          ),
          LessonSection(
            heading: 'When Buying Wins',
            content: 'Buying makes sense when:',
            bullets: [
              'You\'ll stay 7+ years in same location',
              'EMI is close to rent amount',
              'You want stability and customization freedom',
              'Property has good appreciation potential',
            ],
          ),
          LessonSection(
            heading: 'The Rule',
            content: 'Don\'t buy a house because "rent is throwing money away." Run the actual numbers. Sometimes renting and investing the difference builds more wealth than buying.',
          ),
        ],
      ),
      // Lesson 4.5: Avoiding Scams
      LearnLesson(
        id: 'scams',
        title: 'Avoiding Financial Scams',
        readTime: '3 min',
        sections: [
          LessonSection(
            content: 'Scammers are getting smarter, especially with AI. The best defense is skepticism and verification. If something feels off, it probably is.',
          ),
          LessonSection(
            heading: 'The Golden Rule',
            content: 'If it sounds too good to be true, it is too good to be true. No legitimate investment promises 50% guaranteed returns. No Nigerian prince is giving you money. No bank calls asking for your OTP.',
          ),
          LessonSection(
            heading: 'Common Scam Patterns',
            content: 'Red flags to watch for:',
            bullets: [
              'Urgency — "Act now or lose this opportunity"',
              'Guaranteed high returns — No risk, all reward claims',
              'Secrecy — "Don\'t tell anyone about this"',
              'Upfront payments — Pay fees to receive money',
              'Too complex to explain — If you don\'t understand it, don\'t invest',
            ],
          ),
          LessonSection(
            heading: 'Protect Yourself',
            content: 'Practical protection steps:',
            bullets: [
              'Never share OTP, PIN, or passwords with anyone',
              'Verify caller identity — Call back on official numbers',
              'Use strong, unique passwords for financial accounts',
              'Enable 2-factor authentication everywhere',
              'If pressured to decide quickly, say no',
            ],
          ),
          LessonSection(
            heading: 'The Balance',
            content: 'Be cautious, not paranoid. Not every opportunity is a scam. But always verify before transferring money. Take time to research. Legitimate opportunities don\'t disappear if you sleep on them.',
          ),
        ],
      ),
    ],
  ),
];
