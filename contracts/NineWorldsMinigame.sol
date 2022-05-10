// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IVikings.sol";

contract NineWorldsMinigame is Ownable, VRFConsumerBase {
    using Counters for Counters.Counter;
    
    enum NftType {
        Sword,
        Axe,
        Shield
    }

    struct NftStatus {
        NftType nftType;
        uint256 totalPower;
        uint8 dailyMatchCounter;
        uint8 reRollCounter;
        uint256 dailyExpirationTimestamp; // Check exp
        uint256 points;
        uint256 currentMatchId;
    }

    struct Match {
        uint256 matchId;
        uint256 nftMatchCount;
        bool isRerrollEnabled;
        uint256[] validNftsForMatch;
        uint256 matchRandomSeed;
        uint256[] playerNfts;
        uint256[] computerNfts;
        bool isMatchFinished;
        bool didPlayerWin;
    }

    uint256 constant public ONE_DAY_IN_SECONDS = 86400;

    uint256 public nftPointForPlayerWinner;
    uint256 public nftPointForComputerWinner;
    uint256 public totalNfts;
    uint256 public maxMatchesPerDay;
    uint256 public maxNftMatchCount;
    

    mapping (uint256 => Match) public matchesById; // Historical Matches
    mapping (uint256 => NftStatus) public nftStatusById;
    mapping (uint256 => Match) public nftMatchesByNftId;
    mapping (address => uint256) public usersLastMatchId;

    mapping (bytes32 => uint256) public matchesByRequestId;

    Counters.Counter private lastMatchId;

    IVikings public vikingsContract;

    //bytes32 internal keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    bytes32 internal keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
    //uint256 internal feeLink = 1e14; // 0.0001 LINK POLYGON MATIC
    uint256 internal feeLink = 100000000000000000; // 0.0001 LINK RINKEBY MATIC

    event RequestValues(bytes32 requestId);
    event RandomnessEvent(bytes32 requestId);
    event RandomMatchId(bytes32 requestId, uint256 matchId);

    constructor(IVikings _vikingsContract, uint256 _maxMatchesPerDay, uint256 _maxNftMatchCount)
    //VRFConsumerBase(0x3d2341ADb2D31f1c5530cDC622016af293177AE0, 0xb0897686c545045aFc77CF20eC7A532E3120E0F1){
    VRFConsumerBase(0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, 0x01BE23585060835E02B77ef475b0Cc51aA1e0709) {
        vikingsContract = _vikingsContract;
        maxMatchesPerDay = _maxMatchesPerDay;
        maxNftMatchCount = _maxNftMatchCount;
        
    }

    function setNftTypeAndPower(
        uint256[] memory _nftIds, 
        NftType[] memory _nftTypes, 
        uint256[] memory _powers
    ) 
    external 
    onlyOwner 
    {
        require(
            _nftIds.length == _nftTypes.length,
            "NineWorldsMinigame. NftIds length missmatch"
        );
        require(
            _nftTypes.length == _powers.length,
            "NineWorldsMinigame. Powers length missmatch"
        );

        for (uint8 i = 0; i < _nftIds.length; i++) {
            NftStatus storage _nftStatus = nftStatusById[_nftIds[i]];
            _nftStatus.nftType = _nftTypes[i];
            _nftStatus.totalPower = _powers[i];
            totalNfts++;
        }
    }

    function createMatchAndRequestRandom(uint256 _nftMatchCount) external {
        uint256 nftBalance = vikingsContract.balanceOf(_msgSender());
        require (
            _nftMatchCount <= maxNftMatchCount,
            "NineWorldsMinigame: Match nft amount exceed max"
        );
        require (
            nftBalance >= _nftMatchCount,
            "NineWorldsMinigame: Match nft amount exceed user nft amount"
        );

        // Create new Match
        lastMatchId.increment();
        uint256 matchId = lastMatchId.current();

        matchesById[matchId].matchId = matchId;
        matchesById[matchId].nftMatchCount = _nftMatchCount; 
        for (uint8 i = 0; i < nftBalance; i++) {
            uint256 nftId = vikingsContract.tokenOfOwnerByIndex(_msgSender(), i);
            if(nftStatusById[nftId].currentMatchId == 0) {
                if(nftStatusById[nftId].dailyExpirationTimestamp < block.timestamp){
                    nftStatusById[nftId].dailyExpirationTimestamp = block.timestamp + ONE_DAY_IN_SECONDS;
                    nftStatusById[nftId].dailyMatchCounter = 0;
                }
                if(nftStatusById[nftId].dailyMatchCounter < maxMatchesPerDay) {
                    matchesById[matchId].validNftsForMatch.push(nftId);
                }
            }
        }

        require (
            matchesById[matchId].validNftsForMatch.length >= _nftMatchCount,
            "NineWorldsMinigame: Match nft amount exceed user valid nfts to play"
        );

        usersLastMatchId[_msgSender()] = matchId;
        requestRandomValue(matchId);
    }

    function initializeMatchFor(address user) public {
        uint256 matchId = usersLastMatchId[user];
        require(matchesById[matchId].matchRandomSeed > 0, "NineWorldsMinigame: RandomNumber not available yet");
        uint256 randomness = matchesById[matchId].matchRandomSeed;
        uint256 nftMatchCount = matchesById[matchId].nftMatchCount;

        uint256[] memory expandedValues = _expandRandomAux(randomness, nftMatchCount * 2);
        
        uint256[] memory validPlayerNft = matchesById[matchId].validNftsForMatch;
        for (uint8 i = 0; i < nftMatchCount; i++) {
            uint256 randomPlayerNftIndex = _randomIndex(0, validPlayerNft.length, expandedValues[i]);
            uint256 randomPlayerNft = validPlayerNft[randomPlayerNftIndex];
            matchesById[matchId].playerNfts.push(randomPlayerNft);
            nftMatchesByNftId[randomPlayerNftIndex] = matchesById[matchId];
            nftStatusById[randomPlayerNftIndex].dailyMatchCounter++;
            nftStatusById[randomPlayerNftIndex].currentMatchId = matchId;
            uint256 randomComputerNftIndex = _randomIndex(1, totalNfts, expandedValues[i + nftMatchCount]);
            matchesById[matchId].computerNfts.push(randomComputerNftIndex);
        }
    }

    function resolveMatch() public {

    }

    function resolveMatchWithReorder(uint256 indexA, uint256 indexB) public {
        //Check reorder available
        //change position
    }

    function getValidNft(uint8 index) external view returns(uint256) {
        return matchesById[1].validNftsForMatch[index];
    }
    function getValidPlayerNft(uint8 index) external view returns(uint256) {
        return matchesById[1].playerNfts[index];
    }
    function getValidcomputerNft(uint8 index) external view returns(uint256) {
        return matchesById[1].computerNfts[index];
    }

    function setNftPointForPlayerWinner(uint256 _points) external onlyOwner {
        nftPointForPlayerWinner = _points;
    }

    function setNftPointForComputerWinner(uint256 _points) external onlyOwner {
        nftPointForComputerWinner = _points;
    }

    function setMaxMatchesPerDay(uint256 _maxMatches) external onlyOwner {
        maxMatchesPerDay = _maxMatches;
    }

    function setMaxNftMatchCount(uint256 _maxNftMatchCount) external onlyOwner {
        maxNftMatchCount = _maxNftMatchCount;
    }

    function _expandRandomAux(uint256 randomValue, uint256 n) internal pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
    }

    function requestRandomValue(uint256 _matchId) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= feeLink, "NineWorldsMinigame: Not enough LINK, fill contract with LINK");
        requestId = requestRandomness(keyHash, feeLink);
        matchesByRequestId[requestId] = _matchId;
        emit RequestValues(requestId);
    }

    function _randomIndex(uint256 _minNumber, uint256 _maxNumber, uint256 _randomness) internal view returns (uint256) {
        return (_randomness % _maxNumber) + _minNumber;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 matchId = matchesByRequestId[requestId];
        matchesById[matchId].matchRandomSeed = randomness;

        emit RandomMatchId(requestId, matchId);
        emit RandomnessEvent(requestId);
    }
}
