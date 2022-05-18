const { BN, toWei } = require("web3-utils");

const BASE_URI = "https://vikings-geodb.com/api/";

module.exports.MAX_MATCHES_PER_NFT = 3,
module.exports.MAX_NFTS_PER_MATCH = 5,
module.exports.FEE_RECEIVER = "0x7edf00e300708489765e782e3e402f92d98cf1eb";
module.exports.LENDING_POOL = "0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf";
module.exports.ZERO_BN = new BN("0");
module.exports.ONE_BN = new BN("1");
module.exports.INITIAL_STRENGTH_FACTOR = new BN("10000");
module.exports.INITIAL_FEE_PERCENTAGE = new BN("50000");
module.exports.PID = 1;
module.exports.PENALTY_FACTOR = new BN("20000");
module.exports.FEE_PERCENTAGE =  new BN("50000"); //50%
module.exports.DIV_FACTOR = new BN("100000");
module.exports.ONE_ETHER = new BN(toWei("1", "ether"));
module.exports.ONE_USD = new BN(toWei("1", "mwei"));
module.exports.TEN_USD = new BN(toWei("10", "mwei"));
module.exports.MUL_ETHER = new BN("1000");
module.exports.STAKES_IDS = [new BN("0"), new BN("1"), new BN("2"), new BN("3"), new BN("4"), new BN("5")];
module.exports.DEADLINES = [new BN("4582000"), new BN("5582000"), new BN("6582000"),  new BN("7582000"), new BN("7982000"), new BN("8582000")];
module.exports.STAKE_STATUS = 1;
module.exports.MIN_PARTICIPANTS = 1;
module.exports.DEADLINE = new BN("2592000"); //1 day 86400
module.exports.ACTUAL_OPENING = 400000;
module.exports.MIN_AMOUNT_STAKE = new BN(toWei("1", "mwei"));
module.exports.TEN_ETHER = new BN(toWei("10", "ether"));
module.exports.ONE_HUNDRED_ETHER = new BN(toWei("100", "ether"));
module.exports.RANDOMNESS = "777";
module.exports.EXPONENT = new BN("8");
module.exports.MIN_PERCENTAGE = new BN("0");
module.exports.CHECK_IN_MINS = new BN("2000"); //checks every 12 hours
module.exports.LINK = "0xb0897686c545045aFc77CF20eC7A532E3120E0F1";
module.exports.STAKE_TOKEN = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"; //USDC
module.exports.AM_STAKE_TOKEN = "0x1a13F4Ca1d028320A707D99520AbFefca3998b7F";
module.exports.WMATIC = "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270";
module.exports.AaveIncentivesController = "0x357D51124f59836DeD84c8a1730D72B749d8BC23";
module.exports.VRF_COORDINATOR = "0x3d2341ADb2D31f1c5530cDC622016af293177AE0";
module.exports.KEY_HASH = "0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da";
module.exports.LINK_FEE = new BN(toWei("0.0001", "ether"));
module.exports.WHALE_USER_LINK = "0xb7a298189b2c8b703f34cad886e915008c2db738";
module.exports.WHALE_USER_STAKE_TOKEN = "0xf977814e90da44bfa03b6295a0616a897441acec";
module.exports.BASE_URI = BASE_URI;
module.exports.TOTAL_SUPLIES = [new BN("999"), new BN("9999"), new BN("9000"), new BN("900"), new BN("90"), new BN("9"), new BN("9")];
module.exports.INITIAL_INDEXES = [new BN("1"), new BN("1000"), new BN("10999"), new BN("19999"), new BN("20899"), new BN("20989"), new BN("20998")];
module.exports.STRENGTHS = [new BN("1"), new BN("0"), new BN("1"), new BN("3"), new BN("35"), new BN("215"), new BN("1000")];
module.exports.PRICES = [new BN(toWei("10", "mwei")), new BN(toWei("50", "mwei")),new BN("0"), new BN("0"), new BN("0"), new BN("0"), new BN("0")];
module.exports.PARTICIPATE_AMOUNTS = [new BN(toWei("2", "mwei")), new BN(toWei("2", "mwei")), new BN(toWei("4", "mwei")), new BN(toWei("6", "mwei")), new BN(toWei("10", "mwei")),
        new BN(toWei("15", "mwei")),new BN(toWei("30", "mwei")),new BN(toWei("60", "mwei")),new BN(toWei("120", "mwei")),new BN(toWei("240", "mwei")), new BN(toWei("500", "mwei"))];            
module.exports.BASE_URIS = [BASE_URI, BASE_URI, BASE_URI, BASE_URI, BASE_URI, BASE_URI, BASE_URI];
module.exports.TOTAL_SUPLIES_AUX = [new BN("9"), new BN("19"), new BN("10"), new BN("10"), new BN("15"), new BN("5"), new BN("5")];
module.exports.INITIAL_INDEXES_AUX = [new BN("1"), new BN("10"), new BN("29"), new BN("39"), new BN("49"), new BN("64"), new BN("69")];
module.exports.BASE_EXT = ".json";
module.exports.MAX_BOATS_SUPPLY = new BN("9");