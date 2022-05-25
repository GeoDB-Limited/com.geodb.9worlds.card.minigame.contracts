const { BN } = require("web3-utils");

module.exports.getRandom = () => new BN(Math.floor(Math.random() * 100000).toString());