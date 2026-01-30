import '../models/lesson.dart';

/// All financial literacy lessons.
/// Hardcoded. Comprehensive. Life-changing knowledge.
class LessonsData {
  static const List<Lesson> allLessons = [
    _whyPersonalFinanceMatters,
    _the502030Rule,
    _emergencyFund,
    _compoundInterest,
    _goodDebtVsBadDebt,
    _payYourselfFirst,
    _budgetingBasics,
    _settingFinancialGoals,
    _lifestyleInflation,
    _buildingWealth,
  ];

  // Lesson 1: Why Personal Finance Matters
  static const _whyPersonalFinanceMatters = Lesson(
    id: 'why-finance-matters',
    title: 'Why Personal Finance Matters',
    subtitle: 'The foundation of financial freedom',
    icon: 'foundation',
    sections: [
      LessonSection(
        content:
            'Money touches every part of your life. Where you live, what you eat, how you spend your time, and even your relationships are influenced by your financial situation.',
      ),
      LessonSection(
        title: 'The Real Cost of Financial Ignorance',
        content:
            'Most people spend more time planning a vacation than planning their financial future. This leads to living paycheck to paycheck, drowning in debt, and constant stress about money.',
      ),
      LessonSection(
        type: LessonSectionType.highlight,
        content: 'Financial literacy is not taught in schools. You have to learn it yourself.',
        highlightText: 'Financial literacy is not taught in schools.',
      ),
      LessonSection(
        title: 'What Financial Freedom Really Means',
        content:
            'Financial freedom isn\'t about being rich. It\'s about having enough money that you don\'t have to think about it constantly. It\'s the ability to make life decisions without being overly stressed about the financial impact.',
      ),
      LessonSection(
        type: LessonSectionType.bulletList,
        content: 'Signs you need better financial habits:',
        bulletPoints: [
          'You don\'t know where your money goes each month',
          'You have no savings for emergencies',
          'You carry credit card debt month to month',
          'Money causes you stress or anxiety',
          'You avoid looking at your bank balance',
        ],
      ),
      LessonSection(
        type: LessonSectionType.keyTakeaway,
        content:
            'The best time to start managing your money was yesterday. The second best time is today. Every day you delay costs you future wealth.',
      ),
    ],
  );

  // Lesson 2: The 50-30-20 Rule
  static const _the502030Rule = Lesson(
    id: '50-30-20-rule',
    title: 'The 50-30-20 Rule',
    subtitle: 'A simple framework for your money',
    icon: 'pie_chart',
    sections: [
      LessonSection(
        content:
            'Senator Elizabeth Warren popularized this rule in her book "All Your Worth." It\'s the simplest budgeting framework that actually works.',
      ),
      LessonSection(
        type: LessonSectionType.highlight,
        content: '50% Needs. 30% Wants. 20% Savings. That\'s it.',
        highlightText: '50% Needs. 30% Wants. 20% Savings.',
      ),
      LessonSection(
        title: '50% for Needs',
        content:
            'Half your income goes to things you cannot avoid. These are non-negotiable expenses that you must pay to survive and maintain your basic quality of life.',
        bulletPoints: [
          'Rent or mortgage payments',
          'Utilities (electricity, water, gas)',
          'Groceries (not dining out)',
          'Transportation to work',
          'Insurance premiums',
          'Minimum debt payments',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: '30% for Wants',
        content:
            'This is your lifestyle budget. Things you enjoy but could live without. This is where most people overspend without realizing it.',
        bulletPoints: [
          'Dining out and entertainment',
          'Shopping and hobbies',
          'Subscriptions (Netflix, Spotify)',
          'Vacations and travel',
          'Gym memberships',
          'Upgrades (better phone, nicer car)',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: '20% for Savings',
        content:
            'This is your future. Every rupee here is a soldier working for you. This money builds your emergency fund, retirement, and long-term wealth.',
        bulletPoints: [
          'Emergency fund contributions',
          'Retirement accounts',
          'Investment accounts',
          'Extra debt payments (beyond minimum)',
          'Savings goals',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        type: LessonSectionType.quote,
        content:
            '"Do not save what is left after spending, but spend what is left after saving." — Warren Buffett',
      ),
      LessonSection(
        type: LessonSectionType.keyTakeaway,
        content:
            'The 50-30-20 rule is a guideline, not a rigid law. If your needs exceed 50%, reduce wants first. The key is that savings should never drop below 20%.',
      ),
    ],
  );

  // Lesson 3: Emergency Fund
  static const _emergencyFund = Lesson(
    id: 'emergency-fund',
    title: 'Emergency Fund',
    subtitle: 'Your financial safety net',
    icon: 'shield',
    sections: [
      LessonSection(
        content:
            'Life is unpredictable. Cars break down. People get sick. Jobs disappear. An emergency fund is money set aside specifically for these unexpected events.',
      ),
      LessonSection(
        type: LessonSectionType.highlight,
        content: 'An emergency fund is not an investment. It\'s insurance against life.',
        highlightText: 'It\'s insurance against life.',
      ),
      LessonSection(
        title: 'How Much Do You Need?',
        content:
            'The standard advice is 3-6 months of essential expenses. Not income—expenses. Calculate what you absolutely need to survive each month, then multiply.',
        bulletPoints: [
          'Stable job, dual income: 3 months',
          'Single income household: 4-6 months',
          'Freelancer or variable income: 6-12 months',
          'High job risk or health issues: 6-12 months',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: 'Where to Keep It',
        content:
            'Your emergency fund should be easily accessible but not too easy to spend. A separate savings account works best. Don\'t invest it—you need it available immediately without risk of loss.',
      ),
      LessonSection(
        title: 'What Counts as an Emergency?',
        content: 'Be strict about this. Emergencies are unexpected and necessary.',
        bulletPoints: [
          'Job loss or income reduction',
          'Medical emergencies',
          'Essential car or home repairs',
          'Family emergencies',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: 'What is NOT an Emergency',
        content: 'These are wants disguised as needs.',
        bulletPoints: [
          'Sales or "great deals"',
          'Vacations',
          'New gadgets',
          'Planned expenses you forgot to save for',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        type: LessonSectionType.keyTakeaway,
        content:
            'Start with ₹10,000. Then one month of expenses. Then three months. Build slowly but consistently. Having an emergency fund changes how you sleep at night.',
      ),
    ],
  );

  // Lesson 4: The Power of Compound Interest
  static const _compoundInterest = Lesson(
    id: 'compound-interest',
    title: 'The Power of Compound Interest',
    subtitle: 'The eighth wonder of the world',
    icon: 'trending_up',
    sections: [
      LessonSection(
        content:
            'Albert Einstein reportedly called compound interest "the eighth wonder of the world." Whether he said it or not, the math is undeniable.',
      ),
      LessonSection(
        type: LessonSectionType.highlight,
        content: 'Compound interest is earning interest on your interest. Your money makes money, which makes more money.',
        highlightText: 'Your money makes money, which makes more money.',
      ),
      LessonSection(
        title: 'Simple vs Compound Interest',
        content:
            'Simple interest: You earn interest only on your original amount.\nCompound interest: You earn interest on your original amount PLUS all the interest you\'ve already earned.',
      ),
      LessonSection(
        title: 'The Rule of 72',
        content:
            'Want to know how long it takes to double your money? Divide 72 by your interest rate.\n\nAt 8% return: 72 ÷ 8 = 9 years to double\nAt 12% return: 72 ÷ 12 = 6 years to double\nAt 15% return: 72 ÷ 15 = 4.8 years to double',
      ),
      LessonSection(
        title: 'Time is Your Greatest Asset',
        content:
            'Consider two people:\n\nPerson A starts investing ₹5,000/month at age 25, stops at 35 (10 years).\nPerson B starts investing ₹5,000/month at age 35, continues until 65 (30 years).\n\nAt 10% returns, Person A ends up with MORE money at 65, despite investing for only 10 years vs 30 years. That\'s the power of starting early.',
      ),
      LessonSection(
        type: LessonSectionType.quote,
        content:
            '"The best time to plant a tree was 20 years ago. The second best time is now." — Chinese Proverb',
      ),
      LessonSection(
        type: LessonSectionType.keyTakeaway,
        content:
            'Start investing as early as possible, even if it\'s a small amount. Time in the market beats timing the market. Consistency beats perfection.',
      ),
    ],
  );

  // Lesson 5: Good Debt vs Bad Debt
  static const _goodDebtVsBadDebt = Lesson(
    id: 'good-vs-bad-debt',
    title: 'Good Debt vs Bad Debt',
    subtitle: 'Not all debt is created equal',
    icon: 'balance',
    sections: [
      LessonSection(
        content:
            'Debt gets a bad reputation, but not all debt is harmful. Understanding the difference between good and bad debt can accelerate your wealth building.',
      ),
      LessonSection(
        type: LessonSectionType.highlight,
        content: 'Good debt puts money in your pocket. Bad debt takes money out.',
        highlightText: 'Good debt puts money in your pocket.',
      ),
      LessonSection(
        title: 'Characteristics of Good Debt',
        content: 'Good debt helps you build wealth or increase your earning potential.',
        bulletPoints: [
          'Low interest rate (below 8-10%)',
          'Finances an appreciating asset',
          'Increases your income potential',
          'Has tax benefits',
          'You can comfortably afford the payments',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: 'Examples of Good Debt',
        content: '',
        bulletPoints: [
          'Education loans (if it increases earning potential)',
          'Home loans (property appreciates over time)',
          'Business loans (generates income)',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: 'Characteristics of Bad Debt',
        content: 'Bad debt finances consumption and depreciating assets.',
        bulletPoints: [
          'High interest rate (above 15%)',
          'Finances depreciating assets',
          'Doesn\'t generate income',
          'Used for consumption, not investment',
          'Payments strain your budget',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: 'Examples of Bad Debt',
        content: '',
        bulletPoints: [
          'Credit card debt (18-40% interest)',
          'Personal loans for vacations',
          'Car loans for expensive cars',
          'Buy-now-pay-later for shopping',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: 'The Debt Payoff Priority',
        content:
            '1. Pay minimums on all debts\n2. Attack highest interest debt first\n3. Once paid, roll that payment to next highest\n4. Repeat until debt-free\n\nThis is called the "avalanche method" and saves you the most money.',
      ),
      LessonSection(
        type: LessonSectionType.keyTakeaway,
        content:
            'Eliminate high-interest debt aggressively. Use low-interest debt strategically. Never borrow for consumption. If you can\'t afford it in cash, you can\'t afford it.',
      ),
    ],
  );

  // Lesson 6: Pay Yourself First
  static const _payYourselfFirst = Lesson(
    id: 'pay-yourself-first',
    title: 'Pay Yourself First',
    subtitle: 'The most important financial habit',
    icon: 'savings',
    sections: [
      LessonSection(
        content:
            'Most people pay everyone else first—landlord, utility companies, restaurants—and save whatever is left. The problem? There\'s never anything left.',
      ),
      LessonSection(
        type: LessonSectionType.highlight,
        content: 'When your salary arrives, the first transaction should be to your savings. Not rent. Not bills. Savings.',
        highlightText: 'The first transaction should be to your savings.',
      ),
      LessonSection(
        title: 'Why This Works',
        content:
            'Humans adapt. If you move savings out immediately, you learn to live on what\'s left. You adjust your spending unconsciously. You find ways to make it work.',
      ),
      LessonSection(
        title: 'How to Implement',
        content: '',
        bulletPoints: [
          'Set up automatic transfer on salary day',
          'Transfer to a separate account you don\'t touch',
          'Start with 10% if 20% feels impossible',
          'Increase by 1% every few months',
          'Treat savings like a non-negotiable bill',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: 'The Psychology',
        content:
            'When you pay yourself first, you\'re telling yourself that your future matters. You\'re prioritizing the person you\'ll be in 10, 20, 30 years. Most people sacrifice their future self for their present self.',
      ),
      LessonSection(
        type: LessonSectionType.quote,
        content:
            '"A part of all you earn is yours to keep. It should be not less than a tenth no matter how little you earn." — The Richest Man in Babylon',
      ),
      LessonSection(
        type: LessonSectionType.keyTakeaway,
        content:
            'Automate your savings. Make it happen before you can spend it. Your future self will thank you.',
      ),
    ],
  );

  // Lesson 7: Budgeting Basics
  static const _budgetingBasics = Lesson(
    id: 'budgeting-basics',
    title: 'Budgeting Basics',
    subtitle: 'Tell your money where to go',
    icon: 'calculate',
    sections: [
      LessonSection(
        content:
            'A budget is simply a plan for your money. Without a plan, money disappears without purpose. With a plan, every rupee has a job.',
      ),
      LessonSection(
        type: LessonSectionType.highlight,
        content: 'A budget is not about restriction. It\'s about intention. It\'s giving yourself permission to spend on what matters.',
        highlightText: 'It\'s giving yourself permission to spend.',
      ),
      LessonSection(
        title: 'The Simple Budget Process',
        content: '',
        bulletPoints: [
          '1. Calculate your total monthly income',
          '2. List all your fixed expenses',
          '3. Set aside savings (pay yourself first)',
          '4. Allocate remaining money to categories',
          '5. Track spending throughout the month',
          '6. Review and adjust monthly',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: 'Why Most Budgets Fail',
        content: '',
        bulletPoints: [
          'Too complicated (50 categories)',
          'Too restrictive (no fun money)',
          'Not realistic (ignoring irregular expenses)',
          'No tracking (set and forget)',
          'Giving up after one bad month',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: 'The Key to Budgeting Success',
        content:
            'Don\'t aim for perfection. Aim for progress. A budget that\'s 80% followed is infinitely better than a perfect budget that\'s abandoned. Adjust when life changes. Be flexible with categories, but firm with your savings rate.',
      ),
      LessonSection(
        title: 'Irregular Expenses',
        content:
            'Don\'t forget expenses that don\'t happen monthly: insurance premiums, car servicing, festivals, gifts, annual subscriptions. Divide annual costs by 12 and set aside monthly.',
      ),
      LessonSection(
        type: LessonSectionType.keyTakeaway,
        content:
            'Keep it simple. Track consistently. Review monthly. Adjust without guilt. The best budget is one you\'ll actually follow.',
      ),
    ],
  );

  // Lesson 8: Setting Financial Goals
  static const _settingFinancialGoals = Lesson(
    id: 'financial-goals',
    title: 'Setting Financial Goals',
    subtitle: 'Turn dreams into plans',
    icon: 'flag',
    sections: [
      LessonSection(
        content:
            'Goals without plans are just wishes. Financial goals give your money purpose and your savings motivation. They turn abstract "saving for the future" into concrete targets.',
      ),
      LessonSection(
        type: LessonSectionType.highlight,
        content: 'A goal without a deadline is just a dream. A goal with a deadline and a plan is a project.',
        highlightText: 'A goal with a deadline and a plan is a project.',
      ),
      LessonSection(
        title: 'Types of Financial Goals',
        content: '',
        bulletPoints: [
          'Short-term (under 1 year): Emergency fund, vacation, new phone',
          'Medium-term (1-5 years): Car, wedding, down payment',
          'Long-term (5+ years): House, children\'s education, retirement',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: 'The SMART Framework',
        content: 'Make your goals SMART:',
        bulletPoints: [
          'Specific: "Save ₹5,00,000" not "save money"',
          'Measurable: Track progress monthly',
          'Achievable: Stretch but don\'t break',
          'Relevant: Aligned with your values',
          'Time-bound: "By December 2025"',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: 'Prioritizing Goals',
        content:
            'You can\'t fund everything at once. Prioritize:\n\n1. Emergency fund (non-negotiable first goal)\n2. High-interest debt payoff\n3. Retirement savings (time is crucial)\n4. Other goals based on importance',
      ),
      LessonSection(
        title: 'Breaking Down Goals',
        content:
            'Want ₹6,00,000 in 2 years?\n\n₹6,00,000 ÷ 24 months = ₹25,000/month\n\nNow it\'s not a scary big number. It\'s a manageable monthly target. Track monthly. Celebrate milestones.',
      ),
      LessonSection(
        type: LessonSectionType.keyTakeaway,
        content:
            'Write down your goals. Calculate the monthly contribution needed. Automate the savings. Review quarterly. Adjust as life changes, but never abandon the habit of goal-based saving.',
      ),
    ],
  );

  // Lesson 9: Lifestyle Inflation
  static const _lifestyleInflation = Lesson(
    id: 'lifestyle-inflation',
    title: 'Avoiding Lifestyle Inflation',
    subtitle: 'The silent wealth killer',
    icon: 'warning',
    sections: [
      LessonSection(
        content:
            'You got a raise. Congratulations. But six months later, you\'re still living paycheck to paycheck. Where did the money go? Lifestyle inflation ate it.',
      ),
      LessonSection(
        type: LessonSectionType.highlight,
        content: 'Lifestyle inflation is when your spending increases every time your income increases. You earn more, you spend more. Your wealth stays the same.',
        highlightText: 'You earn more, you spend more.',
      ),
      LessonSection(
        title: 'How It Happens',
        content: '',
        bulletPoints: [
          '"I deserve this" after a promotion',
          'Keeping up with colleagues or friends',
          'Upgrading everything at once',
          'Subscription creep (one more service)',
          'Convenience spending (delivery, cabs)',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: 'The Math That Matters',
        content:
            'Person A earns ₹50,000, spends ₹50,000, saves ₹0.\nPerson B earns ₹50,000, spends ₹40,000, saves ₹10,000.\n\nPerson A gets a 50% raise to ₹75,000.\nIf they inflate lifestyle to ₹75,000, they still save ₹0.\n\nPerson B was building wealth before the raise. The raise accelerates their wealth, not their lifestyle.',
      ),
      LessonSection(
        title: 'The 50% Rule for Raises',
        content:
            'When you get a raise, save at least 50% of the increase. Got a ₹10,000 raise? Increase savings by ₹5,000, spend ₹5,000 on lifestyle. You still feel the benefit, but you\'re building wealth faster.',
      ),
      LessonSection(
        title: 'Questions Before Upgrading',
        content: 'Ask yourself:',
        bulletPoints: [
          'Will this make me happier long-term?',
          'Am I buying this for myself or for others\' approval?',
          'What would I do with this money if I didn\'t spend it?',
          'Is this a one-time expense or recurring commitment?',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        type: LessonSectionType.keyTakeaway,
        content:
            'Live below your means, but not below your dignity. Enjoy life, but don\'t let lifestyle inflation eat your wealth. The goal isn\'t to be miserable—it\'s to be intentional.',
      ),
    ],
  );

  // Lesson 10: Building Long-term Wealth
  static const _buildingWealth = Lesson(
    id: 'building-wealth',
    title: 'Building Long-term Wealth',
    subtitle: 'The marathon mindset',
    icon: 'diamond',
    sections: [
      LessonSection(
        content:
            'Wealth isn\'t built overnight. It\'s built through consistent habits over decades. There are no shortcuts, but there is a reliable path.',
      ),
      LessonSection(
        type: LessonSectionType.highlight,
        content: 'Wealth is what you don\'t see. It\'s the cars not bought, the vacations not taken, the lifestyle not inflated.',
        highlightText: 'Wealth is what you don\'t see.',
      ),
      LessonSection(
        title: 'The Wealth Building Formula',
        content:
            '1. Earn money (increase income over time)\n2. Spend less than you earn (maintain a gap)\n3. Invest the difference (make money work)\n4. Be patient (let time compound)\n\nThat\'s it. No complexity needed.',
      ),
      LessonSection(
        title: 'The Three Stages of Wealth',
        content: '',
        bulletPoints: [
          'Stage 1: Stability - Emergency fund, no bad debt',
          'Stage 2: Security - 1+ years of expenses saved',
          'Stage 3: Freedom - Investments cover expenses',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: 'Wealth Building Habits',
        content: '',
        bulletPoints: [
          'Automate savings and investments',
          'Increase savings rate with every raise',
          'Keep investing regardless of market conditions',
          'Avoid emotional financial decisions',
          'Review and rebalance annually',
          'Stay educated about personal finance',
        ],
        type: LessonSectionType.bulletList,
      ),
      LessonSection(
        title: 'The Long-term Perspective',
        content:
            'The stock market will crash. The economy will struggle. You will face setbacks. None of this matters if you\'re playing the long game. Stay invested. Stay consistent. Time heals volatility.',
      ),
      LessonSection(
        type: LessonSectionType.quote,
        content:
            '"The stock market is a device for transferring money from the impatient to the patient." — Warren Buffett',
      ),
      LessonSection(
        type: LessonSectionType.keyTakeaway,
        content:
            'Building wealth is boring. It\'s the same habits, repeated for decades. But boring works. Exciting usually doesn\'t. Choose boring. Choose wealthy.',
      ),
    ],
  );
}
