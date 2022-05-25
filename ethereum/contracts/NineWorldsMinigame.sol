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

    enum MatchResult {
        Empty,
        Tie,
        ComputerWin,
        PlayerWin
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
        mapping(uint256 => bool) repeatedPlayerRandomNumbers;
        mapping(uint256 => bool) repeatedComputerRandomNumbers;
        bool isMatchFinished;
        MatchResult matchResult;
    }

    uint256 constant public ONE_DAY_IN_SECONDS = 86400;

    uint256 public nftPointForPlayerWinner;
    uint256 public nftPointForComputerWinner;
    uint256 public totalNfts;
    uint256 public maxMatchesPerDay;
    uint256 public maxNftMatchCount;
    uint256 public nftPointForPlayerTie;
    uint256 public nftPointForComputerTie;
    uint256 public maxValidId;
    

    mapping (uint256 => Match) public matchesById; // Historical Matches
    mapping (uint256 => NftStatus) public nftStatusById;
    mapping (uint256 => Match) public nftMatchesByNftId;
    mapping (address => uint256) public usersLastMatchId;

    mapping (bytes32 => uint256) public matchesByRequestId;

    Counters.Counter private lastMatchId;

    IVikings public vikingsContract;

    bytes32 internal keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    uint256 internal feeLink = 1e14; // 0.0001 LINK POLYGON MATIC
    //bytes32 internal keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
    //uint256 internal feeLink = 100000000000000000; // 0.0001 LINK RINKEBY MATIC

    event RequestValues(bytes32 requestId);
    event RandomnessEvent(bytes32 requestId, uint256 matchId);
    event MatchCreated(uint256 matchId, address user);
    event MatchInitialized(uint256 matchId, address initializerUser);
    event MatchResolved(uint256 matchId);

    constructor(
        IVikings _vikingsContract, 
        uint256 _maxMatchesPerDay, 
        uint256 _maxNftMatchCount, 
        uint256 _nftPointForPlayerWinner, 
        uint256 _nftPointForComputerWinner,
        uint256 _nftPointForPlayerTie,
        uint256 _nftPointForComputerTie,
        uint256 _maxValidId
    )
    //VRFConsumerBase(0x3d2341ADb2D31f1c5530cDC622016af293177AE0, 0xb0897686c545045aFc77CF20eC7A532E3120E0F1){
    VRFConsumerBase(0x3d2341ADb2D31f1c5530cDC622016af293177AE0, 0xb0897686c545045aFc77CF20eC7A532E3120E0F1) {
        vikingsContract = _vikingsContract;
        maxMatchesPerDay = _maxMatchesPerDay;
        maxNftMatchCount = _maxNftMatchCount;
        nftPointForPlayerWinner = _nftPointForPlayerWinner;
        nftPointForComputerWinner = _nftPointForComputerWinner;
        nftPointForPlayerTie = _nftPointForPlayerTie;
        nftPointForComputerTie = _nftPointForComputerTie;
        maxValidId = _maxValidId;
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
            _nftStatus.dailyExpirationTimestamp = block.timestamp;
            totalNfts++;
        }
    }

    function createMatchAndRequestRandom(uint256 _nftMatchCount) external {
        require(
            usersLastMatchId[_msgSender()] == 0,
            "NineWorldsMinigame: Pending match"
        );
        require (
            _nftMatchCount <= maxNftMatchCount,
            "NineWorldsMinigame: Match nft amount exceed max"
        );
        uint256 nftBalance = vikingsContract.balanceOf(_msgSender());
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
            if(nftId <= maxValidId){
                if(nftStatusById[nftId].currentMatchId == 0) {
                    if(nftStatusById[nftId].dailyExpirationTimestamp + ONE_DAY_IN_SECONDS < block.timestamp){
                        nftStatusById[nftId].dailyExpirationTimestamp = block.timestamp;
                        nftStatusById[nftId].dailyMatchCounter = 0;
                    }
                    if(nftStatusById[nftId].dailyMatchCounter < maxMatchesPerDay) {
                        matchesById[matchId].validNftsForMatch.push(nftId);
                    }
                }
            }
        }

        require (
            matchesById[matchId].validNftsForMatch.length >= _nftMatchCount,
            "NineWorldsMinigame: Match nft amount exceed user valid nfts to play"
        );

        usersLastMatchId[_msgSender()] = matchId;
        emit MatchCreated(matchId, _msgSender());
        requestRandomValue(matchId);
    }

    function initializeMatchFor(address user) public {
        uint256 matchId = usersLastMatchId[user];
        if(_isOwnerOf(user, matchesById[matchId].validNftsForMatch)) {
            require(matchId != 0, "NineWorldsMinigame: No pending match to initialize");
            require(matchesById[matchId].playerNfts.length == 0, "NineWorldsMinigame: Match is already initialized");
            require(matchesById[matchId].matchRandomSeed > 0, "NineWorldsMinigame: RandomNumber not available yet");
            uint256 randomness = matchesById[matchId].matchRandomSeed;
            uint256 nftMatchCount = matchesById[matchId].nftMatchCount;

            uint256[] memory expandedValues = _expandRandomAux(randomness, nftMatchCount * 2);
            
            uint256[] memory validPlayerNft = matchesById[matchId].validNftsForMatch;
            for (uint8 i = 0; i < nftMatchCount; i++) {
                uint256 randomPlayerNftIndex = _randomIndex(0, validPlayerNft.length, expandedValues[i]);
                

                while(matchesById[matchId].repeatedPlayerRandomNumbers[randomPlayerNftIndex] == true) {
                    randomPlayerNftIndex = (randomPlayerNftIndex + 1) % nftMatchCount;
                }
                uint256 randomPlayerNft = validPlayerNft[randomPlayerNftIndex];
                matchesById[matchId].playerNfts.push(randomPlayerNft);
                matchesById[matchId].repeatedPlayerRandomNumbers[randomPlayerNftIndex] = true;

            // nftMatchesByNftId[randomPlayerNft] = matchesById[matchId];
                nftStatusById[randomPlayerNft].dailyMatchCounter++;
                nftStatusById[randomPlayerNft].currentMatchId = matchId;          

                uint256 randomComputerNftIndex = _randomIndex(1, totalNfts, expandedValues[i + nftMatchCount]);
                while(matchesById[matchId].repeatedComputerRandomNumbers[randomComputerNftIndex] == true) {
                    randomComputerNftIndex = (randomComputerNftIndex + 1) % nftMatchCount;
                }
                matchesById[matchId].computerNfts.push(randomComputerNftIndex);
                matchesById[matchId].repeatedComputerRandomNumbers[randomComputerNftIndex] = true;
            }
        } else {
            matchesById[matchId].isMatchFinished = true;
            usersLastMatchId[user] = 0;
        }
        emit MatchInitialized(matchId, _msgSender());
    }

    function resolveMatch() public {
        uint256 matchId = usersLastMatchId[_msgSender()];
        if(_isOwnerOf(_msgSender(), matchesById[matchId].validNftsForMatch)) {
            require(matchesById[matchId].playerNfts.length > 0, "NineWorldsMinigame: Match is not created or initialized");
            require(!matchesById[matchId].isMatchFinished, "NineWorldsMinigame: Match is finished");
            uint256[] memory playerNfts = matchesById[matchId].playerNfts;
            uint256[] memory computerNfts = matchesById[matchId].computerNfts;
            uint256 playerPoints;
            uint256 computerPoints;
            for (uint8 i = 0; i < matchesById[matchId].nftMatchCount; i++) {
                NftType playerType = nftStatusById[playerNfts[i]].nftType;
                NftType computerType = nftStatusById[computerNfts[i]].nftType;
                
                if (playerType == NftType.Axe && computerType == NftType.Sword) {
                    computerPoints++;
                    //AIWinner;
                } else if (playerType == NftType.Shield && computerType == NftType.Sword) {
                    playerPoints++;
                    //PlayerWinner;
                } else if (playerType == NftType.Shield && computerType == NftType.Axe) {
                    computerPoints++;
                    //AIWinner;
                } else if (playerType == NftType.Sword && computerType == NftType.Axe) {
                    playerPoints++;
                    //PlayerWinner;
                } else if (playerType == NftType.Sword && computerType == NftType.Shield) {
                    computerPoints++;
                    //AIWinner;
                } else if (playerType == NftType.Axe && computerType == NftType.Shield) {
                    playerPoints++;
                    //PlayerWinner;
                } else {
                    //Tie;
                }
                nftStatusById[playerNfts[i]].currentMatchId = 0;
            }

            if(playerPoints > computerPoints) {
                for(uint8 i = 0; i < playerNfts.length; i++) {
                    nftStatusById[playerNfts[i]].points += nftPointForPlayerWinner;
                }
                matchesById[matchId].matchResult = MatchResult.PlayerWin; // Player win
            } else if(computerPoints > playerPoints) {
                for(uint8 i = 0; i < computerNfts.length; i++) {
                    nftStatusById[computerNfts[i]].points += nftPointForComputerWinner;
                }
                matchesById[matchId].matchResult = MatchResult.ComputerWin; // Computer Win
            } else {
                for(uint8 i = 0; i < playerNfts.length; i++) {
                    nftStatusById[playerNfts[i]].points += nftPointForPlayerTie;
                    nftStatusById[computerNfts[i]].points += nftPointForComputerTie;
                }
                matchesById[matchId].matchResult = MatchResult.Tie; // Tie
            }
            matchesById[matchId].isMatchFinished = true;
        }
        matchesById[matchId].isMatchFinished = true;
        usersLastMatchId[_msgSender()] = 0;
        emit MatchResolved(matchId);
    }

    function resolveMatchWithReorder(uint256 indexA, uint256 indexB) external {
        uint256 matchId = usersLastMatchId[_msgSender()];
        
        uint256 playerPower;
        uint256 computerPower;
        (playerPower, computerPower) = getPlayerAndComputerPower(matchId);
        require(
            playerPower > computerPower, 
            "NineWorldsMinigame: Reorder not available: player power is less than computer power"
        );
        uint256[] storage playerNfts = matchesById[matchId].playerNfts;
        uint nftAux = playerNfts[indexB];
        playerNfts[indexB] = playerNfts[indexA];
        playerNfts[indexA] = nftAux;

        resolveMatch();
    }

    function getPlayerAndComputerPower(uint256 matchId) internal view returns (uint256, uint256) {
        Match storage actualMatch = matchesById[matchId];
        uint256 playerPower = 0;
        uint256 computerPower = 0;
        for(uint i = 0; i < actualMatch.nftMatchCount; i++) {
            playerPower += nftStatusById[actualMatch.playerNfts[i]].totalPower;
            computerPower += nftStatusById[actualMatch.computerNfts[i]].totalPower;
        }
        return (playerPower, computerPower);
    }

    function getValidNft(uint256 matchId, uint8 index) external view returns(uint256) {
        return matchesById[matchId].validNftsForMatch[index];
    }
    function getValidPlayerNft(uint256 matchId, uint8 index) external view returns(uint256) {
        return matchesById[matchId].playerNfts[index];
    }
    function getValidComputerNft(uint256 matchId, uint8 index) external view returns(uint256) {
        return matchesById[matchId].computerNfts[index];
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

    function setNftPointForPlayerTie(uint256 _nftPointForPlayerTie) external onlyOwner{
        nftPointForPlayerTie = _nftPointForPlayerTie;
    }

    function setNftPointForComputerTie(uint256 _nftPointForComputerTie) external onlyOwner{
        nftPointForComputerTie = _nftPointForComputerTie;
    }

    function setMaxValidId(uint256 _maxValidId) external onlyOwner{
        maxValidId = _maxValidId;
    }

    function _isOwnerOf(address _owner, uint256[] memory _ids) internal returns (bool) {
        for(uint8 i = 0; i < _ids.length; i++) {
            if(vikingsContract.ownerOf(_ids[i]) != _owner){
                return false;
            }
        }
        return true;
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

        emit RandomnessEvent(requestId, matchId);
    }
}
