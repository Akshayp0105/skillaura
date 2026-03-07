"""
Interview Data — Companies, Coding Questions, Aptitude, Mock Test
Kept in a separate file to avoid bloating main.py
"""

# ═══════════════════════════════════════════════════════════
#  COMPANIES  — imported from companies_data.py (500+ companies)
# ═══════════════════════════════════════════════════════════
from companies_data import COMPANIES  # noqa: F401
from extra_questions import EXTRA_QUESTIONS  # noqa: F401

# ═══════════════════════════════════════════════════════════
#  CODING QUESTIONS  (shared pool, tagged by company)
# ═══════════════════════════════════════════════════════════
CODING_QUESTIONS = [
    {
        "id": "q001", "title": "Two Sum", "difficulty": "Easy", "topic": "Array",
        "companies": ["google","amazon","microsoft","meta","flipkart","zoho"],
        "frequency": 98, "acceptance": 49,
        "description": "Given an array of integers `nums` and an integer `target`, return indices of the two numbers such that they add up to `target`.\n\nYou may assume that each input would have exactly one solution, and you may not use the same element twice.",
        "examples": [
            {"input": "nums = [2,7,11,15], target = 9", "output": "[0,1]", "explanation": "Because nums[0] + nums[1] == 9, we return [0, 1]."},
            {"input": "nums = [3,2,4], target = 6", "output": "[1,2]", "explanation": ""},
        ],
        "constraints": ["2 <= nums.length <= 10^4", "-10^9 <= nums[i] <= 10^9", "Only one valid answer exists."],
        "starter_code": {
            "python": "class Solution:\n    def twoSum(self, nums: list[int], target: int) -> list[int]:\n        # Write your solution here\n        pass",
            "javascript": "/**\n * @param {number[]} nums\n * @param {number} target\n * @return {number[]}\n */\nvar twoSum = function(nums, target) {\n    // Write your solution here\n};",
            "java": "class Solution {\n    public int[] twoSum(int[] nums, int target) {\n        // Write your solution here\n        return new int[0];\n    }\n}",
            "cpp": "class Solution {\npublic:\n    vector<int> twoSum(vector<int>& nums, int target) {\n        // Write your solution here\n        return {};\n    }\n};",
        },
        "test_cases": [
            {"input": "nums=[2,7,11,15]\ntarget=9", "expected": "[0, 1]"},
            {"input": "nums=[3,2,4]\ntarget=6", "expected": "[1, 2]"},
            {"input": "nums=[3,3]\ntarget=6", "expected": "[0, 1]"},
        ],
    },
    {
        "id": "q002", "title": "Reverse Linked List", "difficulty": "Easy", "topic": "Linked List",
        "companies": ["amazon","microsoft","adobe","flipkart","infosys"],
        "frequency": 91, "acceptance": 73,
        "description": "Given the `head` of a singly linked list, reverse the list, and return the reversed list.",
        "examples": [
            {"input": "head = [1,2,3,4,5]", "output": "[5,4,3,2,1]", "explanation": ""},
            {"input": "head = [1,2]",        "output": "[2,1]",       "explanation": ""},
        ],
        "constraints": ["The number of nodes in the list is [0, 5000].", "-5000 <= Node.val <= 5000"],
        "starter_code": {
            "python": "class ListNode:\n    def __init__(self, val=0, next=None):\n        self.val = val\n        self.next = next\n\nclass Solution:\n    def reverseList(self, head):\n        prev = None\n        curr = head\n        # Write your solution here\n        pass",
            "javascript": "var reverseList = function(head) {\n    // Write your solution here\n};",
            "java": "class Solution {\n    public ListNode reverseList(ListNode head) {\n        // Write your solution here\n        return null;\n    }\n}",
            "cpp": "class Solution {\npublic:\n    ListNode* reverseList(ListNode* head) {\n        // Write your solution here\n    }\n};",
        },
        "test_cases": [
            {"input": "head=[1,2,3,4,5]", "expected": "[5, 4, 3, 2, 1]"},
            {"input": "head=[1,2]",       "expected": "[2, 1]"},
        ],
    },
    {
        "id": "q003", "title": "Valid Parentheses", "difficulty": "Easy", "topic": "Stack",
        "companies": ["google","amazon","microsoft","meta","goldman","jpmorgan"],
        "frequency": 88, "acceptance": 40,
        "description": "Given a string `s` containing just the characters `'('`, `')'`, `'{'`, `'}'`, `'['` and `']'`, determine if the input string is valid.\n\nAn input string is valid if:\n- Open brackets must be closed by the same type of brackets.\n- Open brackets must be closed in the correct order.\n- Every close bracket has a corresponding open bracket of the same type.",
        "examples": [
            {"input": 's = "()"',    "output": "true", "explanation": ""},
            {"input": 's = "()[]{}"',"output": "true", "explanation": ""},
            {"input": 's = "(]"',    "output": "false","explanation": ""},
        ],
        "constraints": ["1 <= s.length <= 10^4", "s consists of parentheses only '()[]{}'."],
        "starter_code": {
            "python": "class Solution:\n    def isValid(self, s: str) -> bool:\n        # Write your solution here\n        pass",
            "javascript": "var isValid = function(s) {\n    // Write your solution here\n};",
            "java": "class Solution {\n    public boolean isValid(String s) {\n        // Write your solution here\n        return false;\n    }\n}",
            "cpp": "class Solution {\npublic:\n    bool isValid(string s) {\n        // Write your solution here\n        return false;\n    }\n};",
        },
        "test_cases": [
            {"input": 's="()"',    "expected": "True"},
            {"input": 's="()[]{}"',"expected": "True"},
            {"input": 's="(]"',    "expected": "False"},
        ],
    },
    {
        "id": "q004", "title": "Longest Substring Without Repeating Characters", "difficulty": "Medium", "topic": "Sliding Window",
        "companies": ["amazon","google","microsoft","linkedin","uber","adobe"],
        "frequency": 95, "acceptance": 34,
        "description": "Given a string `s`, find the length of the longest substring without repeating characters.",
        "examples": [
            {"input": 's = "abcabcbb"', "output": "3", "explanation": "The answer is 'abc', with the length of 3."},
            {"input": 's = "bbbbb"',    "output": "1", "explanation": "The answer is 'b', with the length of 1."},
            {"input": 's = "pwwkew"',   "output": "3", "explanation": "The answer is 'wke', with the length of 3."},
        ],
        "constraints": ["0 <= s.length <= 5 * 10^4", "s consists of English letters, digits, symbols and spaces."],
        "starter_code": {
            "python": "class Solution:\n    def lengthOfLongestSubstring(self, s: str) -> int:\n        # Write your solution here\n        pass",
            "javascript": "var lengthOfLongestSubstring = function(s) {\n    // Write your solution here\n};",
            "java": "class Solution {\n    public int lengthOfLongestSubstring(String s) {\n        // Write your solution here\n        return 0;\n    }\n}",
            "cpp": "class Solution {\npublic:\n    int lengthOfLongestSubstring(string s) {\n        // Write your solution here\n        return 0;\n    }\n};",
        },
        "test_cases": [
            {"input": 's="abcabcbb"', "expected": "3"},
            {"input": 's="bbbbb"',    "expected": "1"},
            {"input": 's="pwwkew"',   "expected": "3"},
        ],
    },
    {
        "id": "q005", "title": "Maximum Subarray", "difficulty": "Medium", "topic": "Dynamic Programming",
        "companies": ["amazon","google","microsoft","meta","goldman"],
        "frequency": 90, "acceptance": 50,
        "description": "Given an integer array `nums`, find the subarray with the largest sum, and return its sum.",
        "examples": [
            {"input": "nums = [-2,1,-3,4,-1,2,1,-5,4]", "output": "6", "explanation": "The subarray [4,-1,2,1] has the largest sum 6."},
            {"input": "nums = [1]", "output": "1", "explanation": ""},
            {"input": "nums = [5,4,-1,7,8]", "output": "23", "explanation": ""},
        ],
        "constraints": ["1 <= nums.length <= 10^5", "-10^4 <= nums[i] <= 10^4"],
        "starter_code": {
            "python": "class Solution:\n    def maxSubArray(self, nums: list[int]) -> int:\n        # Hint: Kadane's Algorithm\n        pass",
            "javascript": "var maxSubArray = function(nums) {\n    // Hint: Kadane's Algorithm\n};",
            "java": "class Solution {\n    public int maxSubArray(int[] nums) {\n        return 0;\n    }\n}",
            "cpp": "class Solution {\npublic:\n    int maxSubArray(vector<int>& nums) {\n        return 0;\n    }\n};",
        },
        "test_cases": [
            {"input": "nums=[-2,1,-3,4,-1,2,1,-5,4]", "expected": "6"},
            {"input": "nums=[1]", "expected": "1"},
            {"input": "nums=[5,4,-1,7,8]", "expected": "23"},
        ],
    },
    {
        "id": "q006", "title": "Binary Search", "difficulty": "Easy", "topic": "Binary Search",
        "companies": ["google","amazon","meta","apple","infosys","tcs"],
        "frequency": 75, "acceptance": 55,
        "description": "Given an array of integers `nums` which is sorted in ascending order, and an integer `target`, write a function to search `target` in `nums`. If `target` exists, return its index; otherwise, return `-1`.",
        "examples": [
            {"input": "nums = [-1,0,3,5,9,12], target = 9", "output": "4", "explanation": "9 exists in nums and its index is 4."},
            {"input": "nums = [-1,0,3,5,9,12], target = 2", "output": "-1", "explanation": "2 does not exist in nums so return -1."},
        ],
        "constraints": ["1 <= nums.length <= 10^4", "-10^4 < nums[i], target < 10^4", "All the integers in nums are unique."],
        "starter_code": {
            "python": "class Solution:\n    def search(self, nums: list[int], target: int) -> int:\n        pass",
            "javascript": "var search = function(nums, target) {\n};",
            "java": "class Solution {\n    public int search(int[] nums, int target) {\n        return -1;\n    }\n}",
            "cpp": "class Solution {\npublic:\n    int search(vector<int>& nums, int target) {\n        return -1;\n    }\n};",
        },
        "test_cases": [
            {"input": "nums=[-1,0,3,5,9,12]\ntarget=9",  "expected": "4"},
            {"input": "nums=[-1,0,3,5,9,12]\ntarget=2",  "expected": "-1"},
        ],
    },
    {
        "id": "q007", "title": "Merge Two Sorted Lists", "difficulty": "Easy", "topic": "Linked List",
        "companies": ["amazon","microsoft","meta","goldman","jpmorgan"],
        "frequency": 82, "acceptance": 63,
        "description": "You are given the heads of two sorted linked lists `list1` and `list2`. Merge the two lists into one sorted list. Return the head of the merged linked list.",
        "examples": [
            {"input": "list1 = [1,2,4], list2 = [1,3,4]", "output": "[1,1,2,3,4,4]", "explanation": ""},
            {"input": "list1 = [], list2 = []", "output": "[]", "explanation": ""},
        ],
        "constraints": ["0 <= The number of nodes in both lists <= 50", "-100 <= Node.val <= 100"],
        "starter_code": {
            "python": "class Solution:\n    def mergeTwoLists(self, list1, list2):\n        pass",
            "javascript": "var mergeTwoLists = function(list1, list2) {\n};",
            "java": "class Solution {\n    public ListNode mergeTwoLists(ListNode list1, ListNode list2) {\n        return null;\n    }\n}",
            "cpp": "class Solution {\npublic:\n    ListNode* mergeTwoLists(ListNode* list1, ListNode* list2) {\n        return nullptr;\n    }\n};",
        },
        "test_cases": [
            {"input": "list1=[1,2,4]\nlist2=[1,3,4]", "expected": "[1, 1, 2, 3, 4, 4]"},
            {"input": "list1=[]\nlist2=[]", "expected": "[]"},
        ],
    },
    {
        "id": "q008", "title": "Climbing Stairs", "difficulty": "Easy", "topic": "Dynamic Programming",
        "companies": ["amazon","google","apple","zoho","cognizant"],
        "frequency": 78, "acceptance": 52,
        "description": "You are climbing a staircase. It takes `n` steps to reach the top. Each time you can either climb `1` or `2` steps. In how many distinct ways can you climb to the top?",
        "examples": [
            {"input": "n = 2", "output": "2", "explanation": "1+1, 2"},
            {"input": "n = 3", "output": "3", "explanation": "1+1+1, 1+2, 2+1"},
        ],
        "constraints": ["1 <= n <= 45"],
        "starter_code": {
            "python": "class Solution:\n    def climbStairs(self, n: int) -> int:\n        pass",
            "javascript": "var climbStairs = function(n) {\n};",
            "java": "class Solution {\n    public int climbStairs(int n) {\n        return 0;\n    }\n}",
            "cpp": "class Solution {\npublic:\n    int climbStairs(int n) {\n        return 0;\n    }\n};",
        },
        "test_cases": [
            {"input": "n=2", "expected": "2"},
            {"input": "n=3", "expected": "3"},
            {"input": "n=5", "expected": "8"},
        ],
    },
    {
        "id": "q009", "title": "Number of Islands", "difficulty": "Medium", "topic": "Graph/BFS",
        "companies": ["amazon","google","microsoft","meta","uber"],
        "frequency": 87, "acceptance": 57,
        "description": "Given an `m x n` 2D binary grid where `'1'` represents land and `'0'` represents water, return the number of islands.",
        "examples": [
            {"input": 'grid = [["1","1","1","1","0"],["1","1","0","1","0"],["1","1","0","0","0"],["0","0","0","0","0"]]', "output": "1", "explanation": ""},
            {"input": 'grid = [["1","1","0","0","0"],["1","1","0","0","0"],["0","0","1","0","0"],["0","0","0","1","1"]]', "output": "3", "explanation": ""},
        ],
        "constraints": ["m == grid.length", "n == grid[i].length", "1 <= m, n <= 300", "grid[i][j] is '0' or '1'."],
        "starter_code": {
            "python": "class Solution:\n    def numIslands(self, grid: list[list[str]]) -> int:\n        pass",
            "javascript": "var numIslands = function(grid) {\n};",
            "java": "class Solution {\n    public int numIslands(char[][] grid) {\n        return 0;\n    }\n}",
            "cpp": "class Solution {\npublic:\n    int numIslands(vector<vector<char>>& grid) {\n        return 0;\n    }\n};",
        },
        "test_cases": [
            {"input": 'grid=[["1","1","0"],["0","1","0"],["0","0","1"]]', "expected": "2"},
        ],
    },
    {
        "id": "q010", "title": "LRU Cache", "difficulty": "Hard", "topic": "Design",
        "companies": ["google","amazon","microsoft","meta","oracle"],
        "frequency": 85, "acceptance": 42,
        "description": "Design a data structure that follows the constraints of a Least Recently Used (LRU) cache.\n\nImplement the `LRUCache` class:\n- `LRUCache(int capacity)` Initialize the LRU cache with positive size capacity.\n- `int get(int key)` Return the value of the key if the key exists, otherwise return -1.\n- `void put(int key, int value)` Update the value of the key if the key exists. Otherwise, add the key-value pair to the cache. If the number of keys exceeds the capacity from this operation, evict the least recently used key.",
        "examples": [
            {"input": 'LRUCache(2), put(1,1), put(2,2), get(1), put(3,3), get(2), put(4,4), get(1), get(3), get(4)', "output": "[null,null,null,1,null,-1,null,-1,3,4]", "explanation": ""},
        ],
        "constraints": ["1 <= capacity <= 3000", "0 <= key <= 10^4", "0 <= value <= 10^5"],
        "starter_code": {
            "python": "from collections import OrderedDict\n\nclass LRUCache:\n    def __init__(self, capacity: int):\n        pass\n\n    def get(self, key: int) -> int:\n        pass\n\n    def put(self, key: int, value: int) -> None:\n        pass",
            "javascript": "class LRUCache {\n    constructor(capacity) {}\n    get(key) {}\n    put(key, value) {}\n}",
            "java": "class LRUCache {\n    public LRUCache(int capacity) {}\n    public int get(int key) { return -1; }\n    public void put(int key, int value) {}\n}",
            "cpp": "class LRUCache {\npublic:\n    LRUCache(int capacity) {}\n    int get(int key) { return -1; }\n    void put(int key, int value) {}\n};",
        },
        "test_cases": [
            {"input": "capacity=2\nops=put,get,put,get\nkeys=1,1,2,1\nvals=1,-,2,-", "expected": "[-1, 1]"},
        ],
    },
]

# ═══════════════════════════════════════════════════════════
#  APTITUDE QUESTIONS
# ═══════════════════════════════════════════════════════════
APTITUDE_CATEGORIES = [
    {"id": "quantitative",  "name": "Quantitative",      "icon": "calculate",  "questions": 50, "avg_time": 15},
    {"id": "logical",       "name": "Logical Reasoning", "icon": "psychology", "questions": 40, "avg_time": 18},
    {"id": "verbal",        "name": "Verbal Ability",    "icon": "spellcheck", "questions": 45, "avg_time": 12},
    {"id": "data_interp",   "name": "Data Interpretation","icon":"bar_chart",  "questions": 30, "avg_time": 20},
]

APTITUDE_QUESTIONS = {
    "quantitative": [
        {
            "id": "aq01", "question": "A train travels at 60 km/h. How long does it take to cover 150 km?",
            "options": ["2 hours", "2.5 hours", "3 hours", "1.5 hours"],
            "answer": 1, "explanation": "Time = Distance / Speed = 150 / 60 = 2.5 hours"
        },
        {
            "id": "aq02", "question": "If 20% of a number is 50, what is the number?",
            "options": ["200", "250", "300", "150"],
            "answer": 1, "explanation": "x * 20/100 = 50 → x = 50 * 5 = 250"
        },
        {
            "id": "aq03", "question": "A shopkeeper sells an article at Rs.120 making a profit of 20%. Find the cost price.",
            "options": ["Rs.96", "Rs.100", "Rs.90", "Rs.110"],
            "answer": 1, "explanation": "CP = SP / (1 + profit%) = 120 / 1.2 = 100"
        },
        {
            "id": "aq04", "question": "The average of 5 numbers is 27. If one number is excluded, the average becomes 25. What is the excluded number?",
            "options": ["30", "35", "40", "45"],
            "answer": 1, "explanation": "Total = 5*27 = 135; New total = 4*25 = 100; Excluded = 135 - 100 = 35"
        },
        {
            "id": "aq05", "question": "Two pipes A and B can fill a tank in 12 hours and 18 hours. If opened together, in how many hours will they fill the tank?",
            "options": ["6.4 hours", "7.2 hours", "8 hours", "9 hours"],
            "answer": 1, "explanation": "Combined rate = 1/12 + 1/18 = 5/36 per hour. Time = 36/5 = 7.2 hours"
        },
        {
            "id": "aq06", "question": "Find the simple interest on Rs. 5000 at 8% per annum for 3 years.",
            "options": ["Rs. 1000", "Rs. 1200", "Rs. 1500", "Rs. 1800"],
            "answer": 1, "explanation": "SI = P*R*T/100 = 5000*8*3/100 = 1200"
        },
        {
            "id": "aq07", "question": "If the ratio of A to B is 3:4 and B to C is 2:3, find A:B:C.",
            "options": ["3:4:6", "6:8:12", "9:12:18", "3:8:6"],
            "answer": 0, "explanation": "A:B = 3:4, B:C = 2:3 = 4:6. So A:B:C = 3:4:6"
        },
        {
            "id": "aq08", "question": "A can do a work in 20 days. B in 30 days. Both together finish in?",
            "options": ["10 days", "12 days", "15 days", "8 days"],
            "answer": 1, "explanation": "Combined = 1/20 + 1/30 = 5/60 = 1/12. Time = 12 days."
        },
        {
            "id": "aq09", "question": "What is 15% of 240?",
            "options": ["36", "32", "30", "38"],
            "answer": 0, "explanation": "15/100 * 240 = 36"
        },
        {
            "id": "aq10", "question": "Speed of a boat in still water is 15 km/h. Current flows at 3 km/h. Find upstream speed.",
            "options": ["18 km/h", "12 km/h", "10 km/h", "15 km/h"],
            "answer": 1, "explanation": "Upstream = Speed - Current = 15 - 3 = 12 km/h"
        },
        {
            "id": "aq11", "question": "What is 2^10?",
            "options": ["512", "1024", "2048", "256"],
            "answer": 1, "explanation": "2^10 = 1024"
        },
        {
            "id": "aq12", "question": "Find the LCM of 12 and 18.",
            "options": ["36", "72", "24", "6"],
            "answer": 0, "explanation": "LCM(12,18) = 36"
        },
        {
            "id": "aq13", "question": "A is 20% more than B. B is what percent less than A?",
            "options": ["16.67%", "20%", "25%", "15%"],
            "answer": 0, "explanation": "If B=100, A=120. B is (20/120)*100 = 16.67% less than A."
        },
        {
            "id": "aq14", "question": "Compound interest on Rs. 1000 at 10% for 2 years?",
            "options": ["Rs. 200", "Rs. 210", "Rs. 220", "Rs. 230"],
            "answer": 1, "explanation": "CI = 1000 * (1.1)^2 - 1000 = 1210 - 1000 = 210"
        },
        {
            "id": "aq15", "question": "The sum of angles of a triangle is?",
            "options": ["90°", "180°", "270°", "360°"],
            "answer": 1, "explanation": "Sum of interior angles of a triangle = 180°"
        },
    ],
    "logical": [
        {
            "id": "lq01", "question": "All cats are animals. All animals have legs. Therefore:",
            "options": ["Some cats have legs", "All cats have legs", "No cats have legs", "Some animals are cats"],
            "answer": 1, "explanation": "By syllogism: All cats are animals AND all animals have legs → All cats have legs."
        },
        {
            "id": "lq02", "question": "Find the next: 2, 6, 12, 20, 30, ?",
            "options": ["40", "42", "44", "36"],
            "answer": 1, "explanation": "Pattern: n*(n+1). n=1:2, n=2:6, n=3:12, n=4:20, n=5:30, n=6:42"
        },
        {
            "id": "lq03", "question": "DCBA is to ABCD as WXYZ is to:",
            "options": ["ZYXW", "XYZW", "WZYX", "YXWZ"],
            "answer": 0, "explanation": "Reverse the letters: WXYZ reversed is ZYXW."
        },
        {
            "id": "lq04", "question": "If A = 1, B = 2... Z = 26, what is the value of CAB?",
            "options": ["6", "5", "8", "12"],
            "answer": 0, "explanation": "C=3, A=1, B=2 → sum = 6"
        },
        {
            "id": "lq05", "question": "Which one does not belong? Lion, Tiger, Crocodile, Leopard",
            "options": ["Lion", "Tiger", "Crocodile", "Leopard"],
            "answer": 2, "explanation": "Crocodile is a reptile. The rest are mammals/big cats."
        },
        {
            "id": "lq06", "question": "Find the odd one: January, March, May, June, July",
            "options": ["January", "March", "June", "July"],
            "answer": 2, "explanation": "June has 30 days. All others in the list have 31 days."
        },
        {
            "id": "lq07", "question": "Complete the analogy: Doctor : Hospital :: Teacher : ?",
            "options": ["Book", "School", "Student", "Class"],
            "answer": 1, "explanation": "Doctor works in Hospital; Teacher works in School."
        },
        {
            "id": "lq08", "question": "Next term: 1, 4, 9, 16, 25, ?",
            "options": ["30", "36", "49", "35"],
            "answer": 1, "explanation": "Perfect squares: 1²,2²,3²,4²,5² → 6²=36"
        },
        {
            "id": "lq09", "question": "If WINDOW is coded as WNDOWI, how is RETURN coded?",
            "options": ["RTRENU", "RTRNUE", "RRTNEU", "RTUREN"],
            "answer": 0, "explanation": "Pattern: swap pairs of letters. RE→ER, TU→UT, RN→NR → RRTNUE... (varies per scheme)"
        },
        {
            "id": "lq10", "question": "In a row of boys, Raju is 7th from left and 13th from right. How many boys are there?",
            "options": ["18", "19", "20", "21"],
            "answer": 1, "explanation": "Total = 7 + 13 - 1 = 19"
        },
    ],
    "verbal": [
        {
            "id": "vq01", "question": "Choose the correct synonym for 'Eloquent':",
            "options": ["Silent", "Fluent", "Confused", "Dull"],
            "answer": 1, "explanation": "'Eloquent' means well-spoken/fluent in expression."
        },
        {
            "id": "vq02", "question": "Antonym of 'Benevolent':",
            "options": ["Kind", "Malevolent", "Generous", "Charitable"],
            "answer": 1, "explanation": "Benevolent = kind. Malevolent = wishing harm. They are antonyms."
        },
        {
            "id": "vq03", "question": "Choose the correctly spelled word:",
            "options": ["Accomodate", "Acommodate", "Accommodate", "Acomodate"],
            "answer": 2, "explanation": "The correct spelling is 'Accommodate' (double c, double m)."
        },
        {
            "id": "vq04", "question": "Fill in the blank: She _____ to the store yesterday.",
            "options": ["goes", "went", "go", "going"],
            "answer": 1, "explanation": "Past tense of 'go' is 'went'."
        },
        {
            "id": "vq05", "question": "Identify the idiom: 'Bite the bullet'",
            "options": ["To eat something hard", "To endure pain bravely", "To shoot a gun", "To argue"],
            "answer": 1, "explanation": "'Bite the bullet' means to endure a painful situation bravely."
        },
        {
            "id": "vq06", "question": "Which sentence uses the correct article? ",
            "options": ["He is a honest man.", "She ate an apple.", "I saw a elephant.", "He read an history book."],
            "answer": 1, "explanation": "'An apple' is correct. 'An' is used before vowel sounds."
        },
        {
            "id": "vq07", "question": "One word substitute for 'Fear of heights':",
            "options": ["Claustrophobia", "Acrophobia", "Agoraphobia", "Hydrophobia"],
            "answer": 1, "explanation": "Acrophobia = fear of heights."
        },
        {
            "id": "vq08", "question": "Choose the correct passive voice: 'He writes a letter.'",
            "options": ["A letter is written by him.", "A letter was written by him.", "A letter has been written.", "A letter is being written."],
            "answer": 0, "explanation": "Present simple active → present simple passive: 'A letter is written by him.'"
        },
    ],
    "data_interp": [
        {
            "id": "dq01", "question": "A pie chart shows: A=30%, B=25%, C=20%, D=25%. If total students = 200, how many are in category A?",
            "options": ["50", "60", "70", "40"],
            "answer": 1, "explanation": "30% of 200 = 60 students."
        },
        {
            "id": "dq02", "question": "Sales in 2022: Jan=100, Feb=120, Mar=90, Apr=150. Which month had the highest growth?",
            "options": ["Jan-Feb", "Feb-Mar", "Mar-Apr", "All same"],
            "answer": 2, "explanation": "Mar-Apr growth = 150-90 = 60, which is the highest."
        },
        {
            "id": "dq03", "question": "Bar chart: Company A earns Rs.500 Cr, B earns Rs.300 Cr. What is the ratio A:B?",
            "options": ["3:5", "5:3", "2:3", "3:2"],
            "answer": 1, "explanation": "500:300 = 5:3"
        },
        {
            "id": "dq04", "question": "Table: Year 2020: Revenue=1000, Expense=800. Year 2021: Revenue=1200, Expense=900. Profit grew by what %?",
            "options": ["25%", "50%", "75%", "100%"],
            "answer": 1, "explanation": "2020 profit=200, 2021 profit=300. Growth=(300-200)/200*100=50%"
        },
        {
            "id": "dq05", "question": "Line graph shows population: 2000=50L, 2010=70L, 2020=90L. Average decadal growth?",
            "options": ["10L", "20L", "15L", "25L"],
            "answer": 1, "explanation": "Growth per decade: +20L twice. Average = 20L."
        },
    ],
}

# ── Extend coding question pool with extra questions ──────────────────────────
CODING_QUESTIONS.extend(EXTRA_QUESTIONS)
# ═══════════════════════════════════════════════════════════
#  MOCK TEST DOMAINS & QUESTIONS
# ═══════════════════════════════════════════════════════════
MOCK_TEST_DOMAINS = [
    {"id": "dsa",           "name": "Data Structures & Algorithms", "questions": 30, "duration": 60, "difficulty": "Medium"},
    {"id": "cs_fundamentals","name": "CS Fundamentals",            "questions": 30, "duration": 45, "difficulty": "Easy-Med"},
    {"id": "frontend",      "name": "Frontend Development",        "questions": 30, "duration": 45, "difficulty": "Medium"},
    {"id": "backend",       "name": "Backend Development",         "questions": 30, "duration": 60, "difficulty": "Medium"},
    {"id": "system_design", "name": "System Design",               "questions": 20, "duration": 90, "difficulty": "Hard"},
    {"id": "ml",            "name": "Machine Learning",            "questions": 30, "duration": 60, "difficulty": "Medium-Hard"},
]

MOCK_TEST_QUESTIONS = {
    "dsa": [
        {"id": "mt_dsa_01", "question": "What is the time complexity of binary search?",
         "options": ["O(n)", "O(log n)", "O(n log n)", "O(1)"],
         "answer": 1, "explanation": "Binary search halves the search space each step → O(log n).", "section": "Searching"},
        {"id": "mt_dsa_02", "question": "Which data structure uses LIFO principle?",
         "options": ["Queue", "Stack", "Heap", "Tree"],
         "answer": 1, "explanation": "Stack = Last In First Out.", "section": "Basic DS"},
        {"id": "mt_dsa_03", "question": "Best case time complexity of Quicksort?",
         "options": ["O(n²)", "O(n log n)", "O(n)", "O(log n)"],
         "answer": 1, "explanation": "Best and average case of quicksort is O(n log n).", "section": "Sorting"},
        {"id": "mt_dsa_04", "question": "Which traversal of a BST gives sorted output?",
         "options": ["Preorder", "Postorder", "Inorder", "Level order"],
         "answer": 2, "explanation": "Inorder traversal (left-root-right) of BST gives sorted ascending order.", "section": "Trees"},
        {"id": "mt_dsa_05", "question": "What is a complete binary tree?",
         "options": ["All leaves at same level", "All levels filled except possibly the last", "Each node has 0 or 2 children", "None"],
         "answer": 1, "explanation": "Complete binary tree: all levels full except last, last level filled left-to-right.", "section": "Trees"},
        {"id": "mt_dsa_06", "question": "Dijkstra's algorithm is used for?",
         "options": ["MST", "Shortest path", "Topological sort", "Cycle detection"],
         "answer": 1, "explanation": "Dijkstra finds shortest paths from a source in a weighted graph.", "section": "Graphs"},
        {"id": "mt_dsa_07", "question": "Space complexity of merge sort?",
         "options": ["O(1)", "O(log n)", "O(n)", "O(n²)"],
         "answer": 2, "explanation": "Merge sort needs O(n) auxiliary space for merging.", "section": "Sorting"},
        {"id": "mt_dsa_08", "question": "Which of these is NOT a balanced BST?",
         "options": ["AVL Tree", "Red-Black Tree", "B-Tree", "Binary Heap"],
         "answer": 3, "explanation": "Binary Heap is NOT a BST variant; it satisfies the heap property, not BST property.", "section": "Trees"},
        {"id": "mt_dsa_09", "question": "Time complexity of inserting into a hash table (average)?",
         "options": ["O(n)", "O(log n)", "O(1)", "O(n²)"],
         "answer": 2, "explanation": "Hash table insertion is O(1) average case with a good hash function.", "section": "Hashing"},
        {"id": "mt_dsa_10", "question": "Which algorithm is used in Garbage Collection (Mark and Sweep)?",
         "options": ["DFS", "BFS", "Both DFS and BFS", "Heap sort"],
         "answer": 0, "explanation": "Mark and Sweep uses DFS to traverse object references.", "section": "Graphs"},
        {"id": "mt_dsa_11", "question": "What is memoization?",
         "options": ["Storing results of expensive function calls", "A sorting technique", "A graph algorithm", "Memory allocation"],
         "answer": 0, "explanation": "Memoization caches results of function calls to avoid redundant computation (top-down DP).", "section": "DP"},
        {"id": "mt_dsa_12", "question": "Which DS is ideal for implementing a priority queue?",
         "options": ["Stack", "Queue", "Heap", "Linked List"],
         "answer": 2, "explanation": "A heap (min/max) gives O(log n) insert and O(1) peek for priority queues.", "section": "Heap"},
        {"id": "mt_dsa_13", "question": "Kruskal's algorithm builds?",
         "options": ["Shortest path tree", "Minimum spanning tree", "Max flow", "DFS tree"],
         "answer": 1, "explanation": "Kruskal's greedily adds edges by weight to build a Minimum Spanning Tree.", "section": "Graphs"},
        {"id": "mt_dsa_14", "question": "What is the worst-case time complexity of QuickSort?",
         "options": ["O(n log n)", "O(n)", "O(n²)", "O(log n)"],
         "answer": 2, "explanation": "Worst case (already sorted + bad pivot) = O(n²).", "section": "Sorting"},
        {"id": "mt_dsa_15", "question": "A deque (double-ended queue) allows insertion/deletion from?",
         "options": ["Only front", "Only rear", "Both ends", "Middle only"],
         "answer": 2, "explanation": "Deque allows O(1) push/pop at both front and rear.", "section": "Basic DS"},
    ],
    "cs_fundamentals": [
        {"id": "mt_cs_01", "question": "What does CPU stand for?",
         "options": ["Central Processing Unit", "Computer Personal Unit", "Central Program Utility", "Core Processing Unit"],
         "answer": 0, "explanation": "CPU = Central Processing Unit — the brain of the computer.", "section": "Hardware"},
        {"id": "mt_cs_02", "question": "Which layer of OSI model handles routing?",
         "options": ["Data Link", "Transport", "Network", "Application"],
         "answer": 2, "explanation": "Network layer (Layer 3) handles routing and IP addressing.", "section": "Networks"},
        {"id": "mt_cs_03", "question": "What is a deadlock?",
         "options": ["A process crash", "Circular wait among processes", "Memory overflow", "Infinite loop"],
         "answer": 1, "explanation": "Deadlock = processes waiting forever for resources held by each other.", "section": "OS"},
        {"id": "mt_cs_04", "question": "Which protocol is used to send emails?",
         "options": ["HTTP", "FTP", "SMTP", "DNS"],
         "answer": 2, "explanation": "SMTP (Simple Mail Transfer Protocol) is used to send emails.", "section": "Networks"},
        {"id": "mt_cs_05", "question": "Virtual memory is located on?",
         "options": ["RAM", "Hard disk", "Cache", "CPU registers"],
         "answer": 1, "explanation": "Virtual memory uses hard disk space to extend apparent RAM capacity.", "section": "OS"},
        {"id": "mt_cs_06", "question": "What is a primary key in DBMS?",
         "options": ["A key used to encrypt data", "A unique identifier for each record", "The first column", "A foreign key"],
         "answer": 1, "explanation": "Primary key uniquely identifies each row in a table and cannot be NULL.", "section": "DBMS"},
        {"id": "mt_cs_07", "question": "ACID properties belong to?",
         "options": ["HTTP", "Database transactions", "Network protocols", "File systems"],
         "answer": 1, "explanation": "ACID (Atomicity, Consistency, Isolation, Durability) are properties of DB transactions.", "section": "DBMS"},
        {"id": "mt_cs_08", "question": "What is polymorphism in OOP?",
         "options": ["Multiple inheritance", "Same interface, different implementations", "Data hiding", "Code reuse via inheritance"],
         "answer": 1, "explanation": "Polymorphism = one interface, many forms (method overloading/overriding).", "section": "OOP"},
        {"id": "mt_cs_09", "question": "HTTP status code 404 means?",
         "options": ["Internal Server Error", "Unauthorized", "Not Found", "OK"],
         "answer": 2, "explanation": "404 = Not Found — the requested resource doesn't exist on the server.", "section": "Networks"},
        {"id": "mt_cs_10", "question": "Which of these is a compiled language?",
         "options": ["Python", "JavaScript", "C++", "Ruby"],
         "answer": 2, "explanation": "C++ is compiled directly to machine code. Python/JS are interpreted.", "section": "Languages"},
    ],
    "frontend": [
        {"id": "mt_fe_01", "question": "What does CSS stand for?",
         "options": ["Computer Style Sheets", "Cascading Style Sheets", "Creative Style System", "Coded Style Sheets"],
         "answer": 1, "explanation": "CSS = Cascading Style Sheets — used for styling HTML elements.", "section": "CSS"},
        {"id": "mt_fe_02", "question": "Which HTML tag is used for the largest heading?",
         "options": ["<h6>", "<h1>", "<header>", "<head>"],
         "answer": 1, "explanation": "<h1> defines the most important/largest heading.", "section": "HTML"},
        {"id": "mt_fe_03", "question": "In React, what is a 'hook'?",
         "options": ["A lifecycle method", "A function for state/effects in functional components", "A class method", "A CSS feature"],
         "answer": 1, "explanation": "React hooks (useState, useEffect, etc.) allow functional components to use state and lifecycle features.", "section": "React"},
        {"id": "mt_fe_04", "question": "What is the box model in CSS?",
         "options": ["A 3D rendering model", "Content + Padding + Border + Margin", "A grid system", "A layout algorithm"],
         "answer": 1, "explanation": "CSS box model: content area surrounded by padding, border, and margin.", "section": "CSS"},
        {"id": "mt_fe_05", "question": "Which is NOT a JavaScript data type?",
         "options": ["Number", "Boolean", "Character", "Symbol"],
         "answer": 2, "explanation": "JavaScript has no 'Character' type. Single chars are just strings.", "section": "JavaScript"},
        {"id": "mt_fe_06", "question": "What does 'async/await' do in JavaScript?",
         "options": ["Creates threads", "Handles asynchronous operations synchronously", "Blocks the main thread", "Creates callbacks"],
         "answer": 1, "explanation": "async/await is syntactic sugar over Promises for cleaner async code.", "section": "JavaScript"},
        {"id": "mt_fe_07", "question": "What is 'Virtual DOM' in React?",
         "options": ["A browser API", "A lightweight copy of real DOM for efficient updates", "A CSS feature", "A testing tool"],
         "answer": 1, "explanation": "React's Virtual DOM is a JS object representation of the real DOM used to batch and optimize updates.", "section": "React"},
        {"id": "mt_fe_08", "question": "Which CSS property makes an element flex?",
         "options": ["display: block", "display: flex", "float: left", "position: flex"],
         "answer": 1, "explanation": "display: flex enables flexbox layout on a container.", "section": "CSS"},
        {"id": "mt_fe_09", "question": "localStorage vs sessionStorage: what's the difference?",
         "options": ["No difference", "localStorage persists; sessionStorage cleared on tab close", "sessionStorage is larger", "localStorage is session-based"],
         "answer": 1, "explanation": "localStorage persists across sessions; sessionStorage is cleared when the browser tab closes.", "section": "JavaScript"},
        {"id": "mt_fe_10", "question": "What is 'prop drilling' in React?",
         "options": ["Drilling holes in components", "Passing props through many nested levels", "A performance issue", "A routing technique"],
         "answer": 1, "explanation": "Prop drilling = passing data through many component levels unnecessarily. Use Context API or Redux to solve.", "section": "React"},
    ],
    "backend": [
        {"id": "mt_be_01", "question": "REST stands for?",
         "options": ["Representational State Transfer", "Remote Execution Standard Tools", "Relational Entity State Technology", "None"],
         "answer": 0, "explanation": "REST = Representational State Transfer — an architectural style for web APIs.", "section": "API Design"},
        {"id": "mt_be_02", "question": "Which HTTP method is idempotent?",
         "options": ["POST", "PUT", "DELETE", "Both PUT and DELETE"],
         "answer": 3, "explanation": "PUT and DELETE are idempotent — calling them multiple times has the same effect as once.", "section": "HTTP"},
        {"id": "mt_be_03", "question": "What is database indexing used for?",
         "options": ["Security", "Speed up query lookups", "Data backup", "Normalization"],
         "answer": 1, "explanation": "Indexes speed up SELECT queries at the cost of extra write overhead.", "section": "DBMS"},
        {"id": "mt_be_04", "question": "What is JWT?",
         "options": ["Java Web Template", "JSON Web Token", "JavaScript Web Toolkit", "None"],
         "answer": 1, "explanation": "JWT = JSON Web Token — a compact, URL-safe token for authentication/authorization.", "section": "Auth"},
        {"id": "mt_be_05", "question": "In SQL, which clause filters grouped results?",
         "options": ["WHERE", "HAVING", "GROUP BY", "ORDER BY"],
         "answer": 1, "explanation": "HAVING filters groups produced by GROUP BY, unlike WHERE which filters rows.", "section": "SQL"},
        {"id": "mt_be_06", "question": "What does ORM stand for?",
         "options": ["Object Reference Model", "Object Relational Mapping", "Operational Runtime Manager", "None"],
         "answer": 1, "explanation": "ORM maps database tables to objects in code (e.g., SQLAlchemy, Hibernate).", "section": "DBMS"},
        {"id": "mt_be_07", "question": "Which of these is a NoSQL database?",
         "options": ["PostgreSQL", "MySQL", "MongoDB", "SQLite"],
         "answer": 2, "explanation": "MongoDB is a document-based NoSQL database.", "section": "DBMS"},
        {"id": "mt_be_08", "question": "What is a microservice?",
         "options": ["A tiny frontend component", "An independently deployable service", "A database", "A HTTP method"],
         "answer": 1, "explanation": "Microservices are small, independent services each responsible for one business function.", "section": "Architecture"},
        {"id": "mt_be_09", "question": "What does 'N+1 query problem' refer to?",
         "options": ["Too many databases", "1 query to get list + N queries for each item", "Nested SQL", "None"],
         "answer": 1, "explanation": "N+1 problem: 1 query fetches records, then N more queries fetch related data — solved with eager loading.", "section": "Performance"},
        {"id": "mt_be_10", "question": "Which caching strategy writes to cache and DB simultaneously?",
         "options": ["Cache-aside", "Write-through", "Write-behind", "Refresh-ahead"],
         "answer": 1, "explanation": "Write-through writes to cache and database at the same time, ensuring consistency.", "section": "Caching"},
    ],
    "ml": [
        {"id": "mt_ml_01", "question": "What is overfitting?",
         "options": ["Model performs well on training, poor on test", "Model fails on training data", "Model has high bias", "Low variance model"],
         "answer": 0, "explanation": "Overfitting: model memorizes training data but fails to generalize to new data.", "section": "Fundamentals"},
        {"id": "mt_ml_02", "question": "Which algorithm is used for classification AND regression?",
         "options": ["K-Means", "Decision Tree", "PCA", "Apriori"],
         "answer": 1, "explanation": "Decision Trees can do both classification (output: class) and regression (output: value).", "section": "Algorithms"},
        {"id": "mt_ml_03", "question": "What does 'gradient descent' minimize?",
         "options": ["Accuracy", "Loss function", "Data variance", "Feature count"],
         "answer": 1, "explanation": "Gradient descent iteratively adjusts weights to minimize the loss/cost function.", "section": "Optimization"},
        {"id": "mt_ml_04", "question": "Which metric is best for imbalanced classification?",
         "options": ["Accuracy", "F1 Score", "MSE", "R²"],
         "answer": 1, "explanation": "F1 Score balances precision and recall, better for imbalanced datasets than accuracy.", "section": "Evaluation"},
        {"id": "mt_ml_05", "question": "Random Forest is an ensemble of?",
         "options": ["Neural Networks", "Decision Trees", "SVMs", "KNN models"],
         "answer": 1, "explanation": "Random Forest = ensemble of many Decision Trees trained on random subsets.", "section": "Algorithms"},
        {"id": "mt_ml_06", "question": "What is the 'kernel trick' in SVM?",
         "options": ["A hardware optimization", "Mapping data to higher dimensions implicitly", "Feature scaling", "Hyperparameter tuning"],
         "answer": 1, "explanation": "Kernel trick allows SVM to compute inner products in high-dimensional space without explicit transformation.", "section": "Algorithms"},
        {"id": "mt_ml_07", "question": "Principal Component Analysis (PCA) is used for?",
         "options": ["Classification", "Clustering", "Dimensionality reduction", "Regression"],
         "answer": 2, "explanation": "PCA reduces the number of features while preserving maximum variance.", "section": "Dimensionality"},
        {"id": "mt_ml_08", "question": "Which activation function suffers from vanishing gradient?",
         "options": ["ReLU", "Sigmoid", "LeakyReLU", "Swish"],
         "answer": 1, "explanation": "Sigmoid saturates at extremes, causing near-zero gradients that slow training.", "section": "Neural Networks"},
        {"id": "mt_ml_09", "question": "What is 'transfer learning'?",
         "options": ["Moving data between devices", "Reusing a pretrained model for a new task", "Training from scratch", "Data augmentation"],
         "answer": 1, "explanation": "Transfer learning reuses knowledge from a pretrained model, reducing training time and data needs.", "section": "Deep Learning"},
        {"id": "mt_ml_10", "question": "L1 regularization is also known as?",
         "options": ["Ridge", "Lasso", "Elastic Net", "Dropout"],
         "answer": 1, "explanation": "L1 = Lasso regularization (adds sum of absolute weights). L2 = Ridge.", "section": "Regularization"},
    ],
}
