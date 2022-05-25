module.exports = {
    skipFiles: ["./NineWorldsMinigame.sol", "Migrations.sol", "./test/VRFCoordinatorMock.sol", "./interfaces/IERC20.sol"],
    providerOptions: {
        "gasLimit": "0x1fffffffffffff",
        "default_balance_ether": 1000000,
        "fork": "https://matic-mainnet.chainstacklabs.com",
        "unlocked_accounts": ["0xb7a298189b2c8b703f34cad886e915008c2db738", "0xf977814e90da44bfa03b6295a0616a897441acec"],
        "total_accounts": 100,
    }
}