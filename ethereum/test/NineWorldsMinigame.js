const NineWorldsMinigameTest = artifacts.require("./NineWorldsMinigameTest.sol");
const IERC20 = artifacts.require("./IERC20.sol");
const VRFCoordinatorMock = artifacts.require("VRFCoordinatorMock");
const Vikings = artifacts.require("./Vikings.sol");
const { expectEvent, expectRevert, BN, time, constants} = require("@openzeppelin/test-helpers");
const { toWei, isTopic } = require("web3-utils");
const { constant, errorMsgs, utils } = require("./helpers");
const { MAX_MATCHES_PER_NFT, MAX_NFTS_PER_MATCH, NFT_POINT_PER_PLAYER_WIN, NFT_POINT_PER_COMPUTER_WIN, NFT_POINT_PER_PLAYER_TIE,
    NFT_POINT_PER_COMPUTER_TIE, MAX_VALID_ID, LENDING_POOL, AM_STAKE_TOKEN, ZERO_BN, AaveIncentivesController, ONE_HUNDRED_ETHER, WHALE_USER_STAKE_TOKEN, ONE_BN,
    ONE_ETHER, MIN_PARTICIPANTS, DEADLINE, MIN_AMOUNT_STAKE, LINK, WHALE_USER_LINK, EXPONENT, MIN_PERCENTAGE,
    TOTAL_SUPLIES, INITIAL_INDEXES, STRENGTHS, PRICES, BASE_URIS, STAKE_TOKEN, ONE_USD, TEN_USD, MAX_BOATS_SUPPLY } = constant;
require("chai").should();

contract("NineWorldsMulti", ([owner, user, user2, user3, ...accounts]) => {
    const BOAT_ID = 0;
    const VIKING_ID = 0;
    const INVALID_BOAT_ID = new BN("10");
    const singlePlayerMintId = 2;
    let vikingsContract, vrfCoordinatorMock, minigameContract, link;

    beforeEach("Deploy contracts", async () => {
        const currentTime = await time.latest();
        startTimes = new Array(TOTAL_SUPLIES.length).fill(currentTime);
        endTimes = new Array(TOTAL_SUPLIES.length).fill(currentTime.add(time.duration.years(1)));

        vikingsContract = await Vikings.new(TOTAL_SUPLIES, INITIAL_INDEXES, startTimes, endTimes, STRENGTHS, PRICES, BASE_URIS, STAKE_TOKEN, owner);
        vrfCoordinatorMock = await VRFCoordinatorMock.new(LINK, { from: owner });
        minigameContract = await NineWorldsMinigameTest.new(
            vikingsContract.address, 
            MAX_MATCHES_PER_NFT, 
            MAX_NFTS_PER_MATCH, 
            NFT_POINT_PER_PLAYER_WIN,
            NFT_POINT_PER_COMPUTER_WIN,
            NFT_POINT_PER_PLAYER_TIE,
            NFT_POINT_PER_COMPUTER_TIE,
            MAX_VALID_ID,
            vrfCoordinatorMock.address
        );
        link = await IERC20.at(LINK);
        await link.transfer(minigameContract.address, new BN(toWei("100", "ether")), { from: WHALE_USER_LINK });
        
    });

    describe("Nine worlds minigame tests", () => {
        describe("Setters tests", () => {
            it("Allow Set nft points for player with owner", async () =>{
                const nftPointForPlayer = new BN('10');
                await minigameContract.setNftPointForPlayerWinner(nftPointForPlayer, {from: owner});
                let result = await minigameContract.nftPointForPlayerWinner();
                result.should.be.bignumber.equal(nftPointForPlayer)
            });
            it("Deny Set nft points for player with user", async () =>{
                const nftPointForPlayer = new BN('10');
                await expectRevert(
                    minigameContract.setNftPointForPlayerWinner(nftPointForPlayer, {from: user}),
                    errorMsgs.onlyOwner
                );
            });
            it("Set nft points for computer", async() => {
                const nftPointForComputer = new BN('10');
                await minigameContract.setNftPointForComputerWinner(nftPointForComputer, {from: owner});
                let result = await minigameContract.nftPointForComputerWinner();
                result.should.be.bignumber.equal(nftPointForComputer) 
            });
            it("Deny Set nft points for computer with user", async () =>{
                const nftPointForComputer = new BN('10');
                await expectRevert(
                    minigameContract.setNftPointForComputerWinner(nftPointForComputer, {from: user}),
                    errorMsgs.onlyOwner
                );
            });
            it("Set max matches per day", async() => {
                const maxMatchesPerDay = new BN('5');
                await minigameContract.setMaxMatchesPerDay(maxMatchesPerDay, {from: owner});
                let result = await minigameContract.maxMatchesPerDay();
                result.should.be.bignumber.equal(maxMatchesPerDay)
            });
            it("Deny Set max matches per day with user", async () =>{
                const maxMatchesPerDay = new BN('5');
                await expectRevert(
                    minigameContract.setMaxMatchesPerDay(maxMatchesPerDay, {from: user}),
                    errorMsgs.onlyOwner
                );
            });
            it("Set max nft count", async() => {
                const maxNftMatchCount = new BN('10');
                await minigameContract.setMaxNftMatchCount(maxNftMatchCount, {from: owner});
                let result = await minigameContract.maxNftMatchCount();
                result.should.be.bignumber.equal(maxNftMatchCount)
            });
            it("Deny Set max nft count with user", async () =>{
                const maxNftMatchCount = new BN('10');
                await expectRevert(
                    minigameContract.setMaxNftMatchCount(maxNftMatchCount, {from: user}),
                    errorMsgs.onlyOwner
                );
            });
            it("Set nft points for player tie", async() => {
                const nftPointForPlayerTie = new BN('10');
                await minigameContract.setNftPointForPlayerTie(nftPointForPlayerTie, {from: owner});
                let result = await minigameContract.nftPointForPlayerTie();
                result.should.be.bignumber.equal(nftPointForPlayerTie)
            });
            it("Deny nft points for player tie with user", async () =>{
                const nftPointForPlayerTie = new BN('10');
                await expectRevert(
                    minigameContract.setNftPointForPlayerTie(nftPointForPlayerTie, {from: user}),
                    errorMsgs.onlyOwner
                );
            });
            it("Set nft points for computer tie", async() => {
                const nftPointForComputerTie = new BN('10');
                await minigameContract.setNftPointForComputerTie(nftPointForComputerTie, {from: owner});
                let result = await minigameContract.nftPointForComputerTie();
                result.should.be.bignumber.equal(nftPointForComputerTie)
            });
            it("Deny nft points for computer tie with user", async () =>{
                const nftPointForComputerTie = new BN('10');
                await expectRevert(
                    minigameContract.setNftPointForComputerTie(nftPointForComputerTie, {from: user}),
                    errorMsgs.onlyOwner
                );
            });
            it("Set max valid id", async() => {
                const maxValidId = new BN('100');
                await minigameContract.setMaxValidId(maxValidId, {from: owner});
                let result = await minigameContract.maxValidId();
                result.should.be.bignumber.equal(maxValidId)
            });
            it("Deny set max valid id with user", async () =>{
                const maxValidId = new BN('100');
                await expectRevert(
                    minigameContract.setMaxValidId(maxValidId, {from: user}),
                    errorMsgs.onlyOwner
                );
            });
            it("Set nft types", async() => {
                const nftIds = [1,2,3,4];
                const nftTypes = [1,2,0,1];
                const nftPower = [1,1,1,2];
                const totalNfts = new BN(`${nftIds.length}`);
                await minigameContract.setNftTypeAndPower(nftIds, nftTypes, nftPower, {from: owner});
                for(let i = 0; i < nftIds; i++){
                    let result = await minigameContract.nftStatusById(nftIds[i]);
                    result.nftType.should.be.equal(nftTypes[i]);
                    result.totalPower.should.be.equal(nftPower[i]);
                    result.dailyExpirationTimestamp.should.be.equal(await time.latest());
                }
                (await minigameContract.totalNfts()).should.be.bignumber.equal(totalNfts);
            });
            it("Deny Set max nft count with user", async () =>{
                const nftIds = [1,2,3,4];
                const nftTypes = [1,2,0,1];
                const nftPower = [1,1,1,2];
                await expectRevert(
                    minigameContract.setNftTypeAndPower(nftIds, nftTypes, nftPower, {from: user}),
                    errorMsgs.onlyOwner
                );
            });
        });
        describe("Functional tests", () => {
            beforeEach(("Generate nfts"), async () => {
                const nftIds = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
                const nftTypes = [0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2];
                const nftPower = [1, 1, 1, 1, 1, 2, 2 ,2, 2, 3, 3, 3, 3, 3, 3];
                await minigameContract.setNftTypeAndPower(nftIds, nftTypes, nftPower, {from: owner});
                for(let i = 0; i < 10; i++) { 
                    await vikingsContract.mintByType(user, 0, {from: owner});
                }
                for(let i = 0; i < 2; i++) { 
                    await vikingsContract.mintByType(user2, 0, {from: owner});
                }
                for(let i = 0; i < 2; i++) { 
                    await vikingsContract.mintByType(user3, 0, {from: owner});
                }
            })  
            describe("Match tests", () => {
                it("Should allow create new match", async () =>{
                    const matchCount = new BN('5');
                    const matchId = new BN('1');
                    const expectedValidNfts = [new BN('1'), new BN('2'), new BN('3'), new BN('4'), new BN('5'), new BN('6'), new BN('7'), new BN('8'), new BN('9'), new BN('10')];
                    const transaction = await minigameContract.createMatchAndRequestRandom(matchCount, { from: user });
                    const requestEvent = expectEvent(transaction, "RequestValues", {});
                    const requestId = requestEvent.args.requestId;
                    const randomValue = utils.getRandom();
                    const receiptObjCall = await vrfCoordinatorMock.callBackWithRandomness(requestId, randomValue, minigameContract.address);
                    await expectEvent.inTransaction(receiptObjCall["receipt"]["transactionHash"], minigameContract, "RandomnessEvent", { requestId: requestId });

                    const match = await minigameContract.matchesById(matchId);
                    match.matchId.should.be.bignumber.equal(matchId);
                    match.nftMatchCount.should.be.bignumber.equal(matchCount);
                    match.matchRandomSeed.should.be.bignumber.equal(randomValue);

                    for(let i = 0; i < expectedValidNfts.length; i++) {
                        (await minigameContract.getValidNft(matchId, i)).should.be.bignumber.equal(expectedValidNfts[i]);
                    }

                });
                it("Should deny create two new matches", async () =>{
                    const matchCount = new BN('5');
                    const matchId = new BN('1');
                    const expectedValidNfts = [new BN('1'), new BN('2'), new BN('3'), new BN('4'), new BN('5'), new BN('6'), new BN('7'), new BN('8'), new BN('9'), new BN('10')];
                    const transaction = await minigameContract.createMatchAndRequestRandom(matchCount, { from: user });
                    const requestEvent = expectEvent(transaction, "RequestValues", {});
                    const requestId = requestEvent.args.requestId;
                    const randomValue = utils.getRandom();
                    const receiptObjCall = await vrfCoordinatorMock.callBackWithRandomness(requestId, randomValue, minigameContract.address);
                    await expectEvent.inTransaction(receiptObjCall["receipt"]["transactionHash"], minigameContract, "RandomnessEvent", { requestId: requestId });

                    const match = await minigameContract.matchesById(matchId);
                    match.matchId.should.be.bignumber.equal(matchId);
                    match.nftMatchCount.should.be.bignumber.equal(matchCount);
                    match.matchRandomSeed.should.be.bignumber.equal(randomValue);

                    for(let i = 0; i < expectedValidNfts.length; i++) {
                        (await minigameContract.getValidNft(matchId, i)).should.be.bignumber.equal(expectedValidNfts[i]);
                    }

                    await expectRevert(
                        minigameContract.createMatchAndRequestRandom(matchCount, { from: user }),
                        errorMsgs.pendingMatch
                    );

                });
                it("Should allow overpass maxMatchesPerDay if actual timestamp > one day", async () =>{
                    const maxMatchesPerDay = 1;
                    const matchCount = new BN('10');
                    const matchId = new BN('1');
                    await minigameContract.setMaxMatchesPerDay(maxMatchesPerDay, {from: owner })
                    await minigameContract.setMaxNftMatchCount(matchCount, {from: owner});
                    const expectedValidNfts = [new BN('1'), new BN('2'), new BN('3'), new BN('4'), new BN('5'), new BN('6'), new BN('7'), new BN('8'), new BN('9'), new BN('10')];
                    const transaction = await minigameContract.createMatchAndRequestRandom(matchCount, { from: user });
                    const requestEvent = expectEvent(transaction, "RequestValues", {});
                    const requestId = requestEvent.args.requestId;
                    const randomValue = utils.getRandom();
                    const receiptObjCall = await vrfCoordinatorMock.callBackWithRandomness(requestId, randomValue, minigameContract.address);
                    await expectEvent.inTransaction(receiptObjCall["receipt"]["transactionHash"], minigameContract, "RandomnessEvent", { requestId: requestId });

                    const match = await minigameContract.matchesById(matchId);
                    match.matchId.should.be.bignumber.equal(matchId);
                    match.nftMatchCount.should.be.bignumber.equal(matchCount);
                    match.matchRandomSeed.should.be.bignumber.equal(randomValue);

                    for(let i = 0; i < expectedValidNfts.length; i++) {
                        (await minigameContract.getValidNft(matchId, i)).should.be.bignumber.equal(expectedValidNfts[i]);
                    }
                    await minigameContract.initializeMatchFor(user, { from: user } );
                    await minigameContract.resolveMatch({ from: user });

                    await time.increase(time.duration.days(2));
                    const matchId2 = new BN("2");
                    const transaction2 = await minigameContract.createMatchAndRequestRandom(matchCount, { from: user });
                    const requestEvent2 = expectEvent(transaction2, "RequestValues", {});
                    const requestId2 = requestEvent2.args.requestId;
                    const randomValue2 = utils.getRandom();
                    const receiptObjCall2 = await vrfCoordinatorMock.callBackWithRandomness(requestId2, randomValue2, minigameContract.address);
                    await expectEvent.inTransaction(receiptObjCall2["receipt"]["transactionHash"], minigameContract, "RandomnessEvent", { requestId: requestId2 });

                    const match2 = await minigameContract.matchesById(matchId2);
                    match2.matchId.should.be.bignumber.equal(matchId2);
                    match2.nftMatchCount.should.be.bignumber.equal(matchCount);
                    match2.matchRandomSeed.should.be.bignumber.equal(randomValue2);

                    for(let i = 0; i < expectedValidNfts.length; i++) {
                        (await minigameContract.getValidNft(matchId, i)).should.be.bignumber.equal(expectedValidNfts[i]);
                    }

                });
                it("Should deny overpass maxMatchesPerDay if actual timestamp < one day", async () =>{
                    const maxMatchesPerDay = 1;
                    const matchCount = new BN('10');
                    const matchId = new BN('1');
                    await minigameContract.setMaxMatchesPerDay(maxMatchesPerDay, {from: owner})
                    await minigameContract.setMaxNftMatchCount(matchCount, {from: owner});
                    const expectedValidNfts = [new BN('1'), new BN('2'), new BN('3'), new BN('4'), new BN('5'), new BN('6'), new BN('7'), new BN('8'), new BN('9'), new BN('10')];
                    const transaction = await minigameContract.createMatchAndRequestRandom(matchCount, { from: user });
                    const requestEvent = expectEvent(transaction, "RequestValues", {});
                    const requestId = requestEvent.args.requestId;
                    const randomValue = utils.getRandom();
                    const receiptObjCall = await vrfCoordinatorMock.callBackWithRandomness(requestId, randomValue, minigameContract.address);
                    await expectEvent.inTransaction(receiptObjCall["receipt"]["transactionHash"], minigameContract, "RandomnessEvent", { requestId: requestId });

                    const match = await minigameContract.matchesById(matchId);
                    match.matchId.should.be.bignumber.equal(matchId);
                    match.nftMatchCount.should.be.bignumber.equal(matchCount);
                    match.matchRandomSeed.should.be.bignumber.equal(randomValue);

                    for(let i = 0; i < expectedValidNfts.length; i++) {
                        (await minigameContract.getValidNft(matchId, i)).should.be.bignumber.equal(expectedValidNfts[i]);
                    }
                    await minigameContract.initializeMatchFor(user, { from: user } );
                    await minigameContract.resolveMatch({ from: user });

                    await expectRevert(
                        minigameContract.createMatchAndRequestRandom(matchCount, { from: user }),
                        errorMsgs.matchNftAmountExceedUserValid
                    );
                });
                it("Should deny create new match if matchCount > maxMatchCount", async () =>{
                    const matchCount = 30;
                    await expectRevert(
                        minigameContract.createMatchAndRequestRandom(matchCount, { from: user }),
                        errorMsgs.matchNftExceedMax
                    );
                });
                it("Should deny create new match if matchCount > userNFT", async () =>{
                    const matchCount = 4;
                    await expectRevert(
                        minigameContract.createMatchAndRequestRandom(matchCount, { from: user2 }),
                        errorMsgs.matchNftAmountExceedUser
                    );
                });
                it("Should deny create new match if matchCount > user valid nfts", async () =>{
                    const maxMatchesPerDay = 1;
                    const matchCount = 2;
                    await minigameContract.setMaxMatchesPerDay(maxMatchesPerDay, {from: owner});
                    const transaction = await minigameContract.createMatchAndRequestRandom(matchCount, { from: user2 });
                    const requestEvent = expectEvent(transaction, "RequestValues", {});
                    const requestId = requestEvent.args.requestId;
                    const receiptObjCall = await vrfCoordinatorMock.callBackWithRandomness(requestId, utils.getRandom(), minigameContract.address);
                    await expectEvent.inTransaction(receiptObjCall["receipt"]["transactionHash"], minigameContract, "RandomnessEvent", { requestId: requestId });
                    await minigameContract.initializeMatchFor(user2, { from: user2 }),
                    await minigameContract.resolveMatch({ from: user2 });
                    
                    await expectRevert(
                        minigameContract.createMatchAndRequestRandom(matchCount, { from: user2 }),
                        errorMsgs.matchNftAmountExceedUserValid
                    );
                }); 
            });
            describe("Initialize match test", () => {
                beforeEach("Create match and generate random number", async () => {
                    const matchCount = 5;
                    const transaction = await minigameContract.createMatchAndRequestRandom(matchCount, { from: user });
                    const requestEvent = expectEvent(transaction, "RequestValues", {});
                    const requestId = requestEvent.args.requestId;
                    const randomValue = utils.getRandom();
                    const receiptObjCall = await vrfCoordinatorMock.callBackWithRandomness(requestId, randomValue, minigameContract.address);
                    await expectEvent.inTransaction(receiptObjCall["receipt"]["transactionHash"], minigameContract, "RandomnessEvent", { requestId: requestId });
                })
                it("Should allow resolve match with user", async () =>{
                    const dailyMatch = new BN("1");
                    const matchId = new BN("1");
                    const matchCount = 5;
                    await minigameContract.initializeMatchFor(user, { from: user} );

                    for(let i = 0; i < matchCount; i++) {
                        const nftId = (await minigameContract.getValidPlayerNft(matchId, i));
                        const nftStatusById = await minigameContract.nftStatusById(nftId);
                        nftStatusById.dailyMatchCounter.should.be.bignumber.equal(dailyMatch);
                        nftStatusById.currentMatchId.should.be.bignumber.equal(matchId);
                    }
                }); 

                it("Should deny resolve match with user if match has been already initialized", async () =>{
                    const dailyMatch = new BN("1");
                    const matchId = new BN("1");
                    const matchCount = 5;
                    await minigameContract.initializeMatchFor(user, { from: user} );

                    for(let i = 0; i < matchCount; i++) {
                        const nftId = (await minigameContract.getValidPlayerNft(matchId, i));
                        const nftStatusById = await minigameContract.nftStatusById(nftId);
                        nftStatusById.dailyMatchCounter.should.be.bignumber.equal(dailyMatch);
                        nftStatusById.currentMatchId.should.be.bignumber.equal(matchId);
                    }

                    await expectRevert(
                        minigameContract.initializeMatchFor(user, { from: user} ),
                        errorMsgs.initializedMatch
                    );
                });

                it("Should deny resolve match with user if match is finished", async () =>{
                    const dailyMatch = new BN("1");
                    const matchId = new BN("1");
                    const matchCount = 5;
                    await minigameContract.initializeMatchFor(user, { from: user} );

                    for(let i = 0; i < matchCount; i++) {
                        const nftId = (await minigameContract.getValidPlayerNft(matchId, i));
                        const nftStatusById = await minigameContract.nftStatusById(nftId);
                        nftStatusById.dailyMatchCounter.should.be.bignumber.equal(dailyMatch);
                        nftStatusById.currentMatchId.should.be.bignumber.equal(matchId);
                    }

                    await minigameContract.resolveMatch({ from: user });

                    await expectRevert(
                        minigameContract.initializeMatchFor(user, { from: user} ),
                        errorMsgs.noPendingMatch
                    );
                }); 
                it("Should deny resolve match with user2 if random number not available", async () =>{
                    const matchCount = 2;
                    const transaction = await minigameContract.createMatchAndRequestRandom(matchCount, { from: user2 });

                    await expectRevert (
                        minigameContract.initializeMatchFor(user2, { from: user2} ),
                        errorMsgs.randomNumber
                    );
                });
                
            }); 
            describe("Resolve match test", () => {
                beforeEach("Initialize match", async () => {
                    const matchCount = 5;
                    const transaction = await minigameContract.createMatchAndRequestRandom(matchCount, { from: user });
                    const requestEvent = expectEvent(transaction, "RequestValues", {});
                    const requestId = requestEvent.args.requestId;
                    const randomValue = utils.getRandom();
                    const receiptObjCall = await vrfCoordinatorMock.callBackWithRandomness(requestId, randomValue, minigameContract.address);
                    await expectEvent.inTransaction(receiptObjCall["receipt"]["transactionHash"], minigameContract, "RandomnessEvent", { requestId: requestId });

                    const nftPointForPlayer = new BN("100")
                    const nftPointForComputer = new BN("10");
                    const nftPointForTie = new BN("5");
                    await minigameContract.setNftPointForPlayerWinner(nftPointForPlayer, {from: owner});
                    await minigameContract.setNftPointForComputerWinner(nftPointForComputer, {from: owner});
                    await minigameContract.setNftPointForPlayerTie(nftPointForTie, {from: owner});
                    await minigameContract.setNftPointForComputerTie(nftPointForTie, {from: owner});
                })
                it("Should allow resolve match with user. Player win", async () =>{
                    const nftPointForPlayer = new BN("100");
                    const nftPointForComputer = new BN("0");
                    const matchId = 2;
                    const matchCount = 2;
                    const transaction = await minigameContract.createMatchAndRequestRandom(matchCount, { from: user3 });
                    const requestEvent = expectEvent(transaction, "RequestValues", {});
                    const requestId = requestEvent.args.requestId;
                    const randomValue = new BN("3"); // Player (14 Shield, 13 Shield) Computer (15 Shield, 3 Sword) NFT Player win
                    const receiptObjCall = await vrfCoordinatorMock.callBackWithRandomness(requestId, randomValue, minigameContract.address);
                    await expectEvent.inTransaction(receiptObjCall["receipt"]["transactionHash"], minigameContract, "RandomnessEvent", { requestId: requestId });
                    await minigameContract.initializeMatchFor(user3, { from: user3 } );

                    await minigameContract.resolveMatch({ from: user3 });
                    for(let i = 0; i < matchCount; i++) {
                        const nftPlayerId = (await minigameContract.getValidPlayerNft(matchId, i));
                        const nftPlayerStatus = await minigameContract.nftStatusById(nftPlayerId);
                        nftPlayerStatus.currentMatchId.should.be.bignumber.equal(new BN("0"));
                        nftPlayerStatus.points.should.be.bignumber.equal(nftPointForPlayer);

                        const nftComputerId = (await minigameContract.getValidComputerNft(matchId, i));
                        const nftComputerStatus = await minigameContract.nftStatusById(nftComputerId);
                        nftComputerStatus.points.should.be.bignumber.equal(nftPointForComputer);
                    }
                });
                it("Should allow resolve match with user. Tie", async () =>{
                    const nftPointForPlayer = new BN("5");
                    const nftPointForComputer = new BN("5");
                    const matchId = 2;
                    const matchCount = 2;
                    const transaction = await minigameContract.createMatchAndRequestRandom(matchCount, { from: user3 });
                    const requestEvent = expectEvent(transaction, "RequestValues", {});
                    const requestId = requestEvent.args.requestId;
                    const randomValue = new BN("12"); // Player (14 Shield, 13 Shield) Computer (13 Shield, 10 Shield) NFT Tie
                    const receiptObjCall = await vrfCoordinatorMock.callBackWithRandomness(requestId, randomValue, minigameContract.address);
                    await expectEvent.inTransaction(receiptObjCall["receipt"]["transactionHash"], minigameContract, "RandomnessEvent", { requestId: requestId });
                    await minigameContract.initializeMatchFor(user3, { from: user3 } );

                    await minigameContract.resolveMatch({ from: user3 });
                    for(let i = 0; i < matchCount; i++) {
                        const nftPlayerId = (await minigameContract.getValidPlayerNft(matchId, i));
                        const nftPlayerStatus = await minigameContract.nftStatusById(nftPlayerId);
                        nftPlayerStatus.currentMatchId.should.be.bignumber.equal(new BN("0"));
                        nftPlayerStatus.points.should.be.bignumber.equal(nftPointForPlayer);

                        const nftComputerId = (await minigameContract.getValidComputerNft(matchId, i));
                        const nftComputerStatus = await minigameContract.nftStatusById(nftComputerId);
                        nftComputerStatus.points.should.be.bignumber.equal(nftPointForComputer);
                    }
                });
                it("Should allow resolve match with user. Computer win", async () =>{
                    const nftPointForPlayer = new BN("0");
                    const nftPointForComputer = new BN("10");
                    const matchId = 2;
                    const matchCount = 2;
                    const transaction = await minigameContract.createMatchAndRequestRandom(matchCount, { from: user3 });
                    const requestEvent = expectEvent(transaction, "RequestValues", {});
                    const requestId = requestEvent.args.requestId;
                    const randomValue = new BN("2"); // Player (14 Shield, 13 Shield) Computer (9 Axe, 7 Axe) NFT Computer win
                    const receiptObjCall = await vrfCoordinatorMock.callBackWithRandomness(requestId, randomValue, minigameContract.address);
                    await expectEvent.inTransaction(receiptObjCall["receipt"]["transactionHash"], minigameContract, "RandomnessEvent", { requestId: requestId });
                    await minigameContract.initializeMatchFor(user3, { from: user3 } );

                    await minigameContract.resolveMatch({ from: user3 });
                    for(let i = 0; i < matchCount; i++) {
                        const nftPlayerId = (await minigameContract.getValidPlayerNft(matchId, i));
                        const nftPlayerStatus = await minigameContract.nftStatusById(nftPlayerId);
                        nftPlayerStatus.currentMatchId.should.be.bignumber.equal(new BN("0"));
                        nftPlayerStatus.points.should.be.bignumber.equal(nftPointForPlayer);

                        const nftComputerId = (await minigameContract.getValidComputerNft(matchId, i));
                        const nftComputerStatus = await minigameContract.nftStatusById(nftComputerId);
                        nftComputerStatus.points.should.be.bignumber.equal(nftPointForComputer);
                    }
                });
                it("Should deny resolve not created match with user2", async () =>{
                    await expectRevert (
                        minigameContract.resolveMatch({ from: user2 }),
                        errorMsgs.notInitializedMatch
                    )
                });
                it("Should deny resolve not initialized match with user2", async () =>{
                    const matchCount = 2;
                    const transaction = await minigameContract.createMatchAndRequestRandom(matchCount, { from: user2 });
                    const requestEvent = expectEvent(transaction, "RequestValues", {});
                    const requestId = requestEvent.args.requestId;
                    const randomValue = utils.getRandom();
                    const receiptObjCall = await vrfCoordinatorMock.callBackWithRandomness(requestId, randomValue, minigameContract.address);
                    await expectEvent.inTransaction(receiptObjCall["receipt"]["transactionHash"], minigameContract, "RandomnessEvent", { requestId: requestId });

                    await expectRevert (
                        minigameContract.resolveMatch({ from: user2 }),
                        errorMsgs.notInitializedMatch
                    )
                });
            });  
        })
    })
})
