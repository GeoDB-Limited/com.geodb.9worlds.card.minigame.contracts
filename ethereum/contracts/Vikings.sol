// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interfaces/IERC20.sol";

contract Vikings is ERC721Enumerable, Pausable, Ownable {
    using Strings for uint256;

    struct Viking {
        uint256 birthTime;
        uint256 strength;
        uint256 tokenType;
        bool isLocked;
    }

    struct MintType {
        uint256 totalSupply;
        uint256 currentSupply;
        uint256 initialIndex;
        uint256 startTime;
        uint256 endTime;
        uint256 strength;
        uint256 price;
        string baseTokenUri;
    }


    string public baseExtension = ".json";
    uint256 public maxAmountMintTx = 20;
    uint256 public totalTypes;
    uint256 public whiteListStartTime;
    uint256 public whiteListEndTime;
    address public feeReceiver;
    IERC20 public saleToken;

    mapping (address => bool) private minters;
    mapping (uint256 => Viking) public vikings;
    mapping (address => uint256) public whiteListAmountLeft;
    mapping (address => uint256) public alreadyMintedAmount;
    mapping (uint256 => MintType) public mintDataType;

    event VikingGenerated(uint256 indexed vikingId, address owner);
    event VikingSale(uint256 indexed vikingId, address owner, uint256 price);
    event VikingLocked(uint256 vikingId, bool vikingStatus);

    constructor(uint256[] memory _totalSupply, uint256[] memory _initialIndex, uint256[] memory _startTime, uint256[] memory _endTime, uint256[] memory _strength, uint256[] memory _price, string[] memory _baseUri, 
    IERC20 _saleToken, address _feeReceiver) ERC721("Vikings", "VIK") {
        require(_totalSupply.length > 0, "Vikings: Invalid parameters length");
        require(_totalSupply.length == _initialIndex.length && _totalSupply.length == _startTime.length && _totalSupply.length == _endTime.length &&
            _totalSupply.length == _strength.length && _totalSupply.length == _price.length && _totalSupply.length == _baseUri.length, "Vikings: Parameters length mismatch");
        for (uint i = 0; i < _totalSupply.length; i++) {
            mintDataType[i].totalSupply = _totalSupply[i];
            mintDataType[i].initialIndex = _initialIndex[i];
            mintDataType[i].startTime = _startTime[i];
            mintDataType[i].endTime = _endTime[i];
            mintDataType[i].strength = _strength[i];
            mintDataType[i].price = _price[i];
            mintDataType[i].baseTokenUri = _baseUri[i];
        }
        totalTypes = _totalSupply.length;
        minters[owner()] = true;
        feeReceiver = _feeReceiver;
        saleToken = _saleToken;
    }

    modifier onlyMinter() {
        require(minters[_msgSender()], "Vikings: The origin is not allowed to mint");
        _;
    }

    modifier checkTypeMint(uint256 _type, uint256 _amount) {
        require(_amount > 0, "Vikings: The amount to mint have to bigger than 0");
        require(maxAmountMintTx >= _amount, "Vikings: The mint amount exceeds the limit in a tx");
        require(totalTypes > _type, "Vikings: Error nonexistent type of mint");
        require(mintDataType[_type].totalSupply >= mintDataType[_type].currentSupply + _amount, "Vikings: Mint error, max supply reached for the specific type");
        _;
    }

    function setBaseURI(uint256 _mintType, string memory _baseUri) external onlyOwner {
        mintDataType[_mintType].baseTokenUri = _baseUri;
    }

    function setMintType(uint256 _mintType, uint256 _totalSupply, uint256 _initialIndex, uint256 _startTime, uint256 _endTime, uint256 _strength, uint256 _price, string memory _baseUri) external onlyOwner {
        mintDataType[_mintType].totalSupply = _totalSupply;
        mintDataType[_mintType].initialIndex = _initialIndex;
        mintDataType[_mintType].startTime = _startTime;
        mintDataType[_mintType].endTime = _endTime;
        mintDataType[_mintType].strength = _strength;
        mintDataType[_mintType].price = _price;
        mintDataType[_mintType].baseTokenUri = _baseUri;
        if(_mintType >= totalTypes) {
            totalTypes++;
        }
    }

    function setBaseExtension(string memory _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    function setSaleToken(IERC20 _saleToken) external onlyOwner {
        saleToken = _saleToken;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function setMaxAmountMintTx(uint256 _maxAmountMintTx) external onlyOwner {
        maxAmountMintTx = _maxAmountMintTx;
    }

    function setWhitelist(uint256 _whiteListStartTime, uint256 _whiteListEndTime, address[] memory _accounts, uint256[] memory _mintAllowed) external onlyOwner {
        require(_whiteListEndTime > _whiteListStartTime, "Vikings: White list error in end time");
        require(_accounts.length == _mintAllowed.length, "Vikings: Parameters length mismatch");
        for (uint256 i = 0; i < _accounts.length; i++) {
            whiteListAmountLeft[_accounts[i]] = _mintAllowed[i];
        }
        whiteListStartTime = _whiteListStartTime;
        whiteListEndTime = _whiteListEndTime;
    }

    function setWhitelistBatch(address[] memory _accounts, uint256[] memory _mintAllowed) external onlyOwner {
        require(_accounts.length > 0, "Vikings: accounts variable length is wrong");
        require(_accounts.length == _mintAllowed.length, "Vikings: Parameters length mismatch");
        for (uint256 i = 0; i < _accounts.length; i++) {
            whiteListAmountLeft[_accounts[i]] += _mintAllowed[i];
        }
    }

    function setMinters(address[] memory _minters, bool[] memory status) external onlyOwner {
        require(_minters.length > 0 && _minters.length == status.length, "Vikings: Error with minters variables");
        for(uint256 i = 0; i < _minters.length; i++) {
            minters[_minters[i]] = status[i];
        }
    }

    function updateStrength(uint256[] memory _vikingIds, uint256[] memory _strengths) external onlyOwner {
        require(_vikingIds.length > 0 && _vikingIds.length == _strengths.length, "Vikings: Error with update strength variables, parameters length mismatch");
        for(uint256 i = 0; i < _vikingIds.length; i++) {
            require(vikings[_vikingIds[i]].strength == 0, "Vikings: Error viking strength already updated");
            vikings[_vikingIds[i]].strength = _strengths[i];
        }
    }

    function deleteWhitelistBatch(address[] memory _accounts) external onlyOwner {
        require(_accounts.length > 0, "Vikings: accounts variable length is wrong");
        for (uint256 i = 0; i < _accounts.length; i++) {
            whiteListAmountLeft[_accounts[i]] = 0;
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function tokenStrength(uint256 _tokenId) external view returns (uint256) {
        return vikings[_tokenId].strength;
    }

    function isVikingLocked(uint256 _tokenId) external view returns (bool) {
        return vikings[_tokenId].isLocked && _exists(_tokenId);
    }

    function getCurrentMaxSupply() external view returns (uint256) {
        return mintDataType[totalTypes - 1].initialIndex + mintDataType[totalTypes - 1].totalSupply;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function saleMint(uint256 _type, uint256 _amount) external checkTypeMint(_type, _amount) {
        require(block.timestamp >= mintDataType[_type].startTime && block.timestamp < mintDataType[_type].endTime, "Vikings: Mint error, wrong time for type sale");
        require(saleToken.balanceOf(_msgSender()) * _amount >= mintDataType[_type].price, "Vikings: Mint sale error, user balance is not enough");
        require(mintDataType[_type].price > 0, "Vikings: Mint type is not for sale");
        if (block.timestamp > whiteListStartTime && block.timestamp <= whiteListEndTime) {
            require(whiteListAmountLeft[_msgSender()] > 0, "Vikings: Mint error, the whitelist is active and the user is not in it");
            require(whiteListAmountLeft[_msgSender()] >= _amount, "Vikings: The amount exceed the the whitelist user allowance");
            whiteListAmountLeft[_msgSender()] -= _amount;
        }
        uint256 indexToMint = mintDataType[_type].currentSupply + mintDataType[_type].initialIndex;
        mintDataType[_type].currentSupply += _amount;
        alreadyMintedAmount[_msgSender()] += _amount;
        for (uint256 i = indexToMint; i < indexToMint + _amount; i++) {
            vikings[i].birthTime = block.timestamp;
            vikings[i].strength = mintDataType[_type].strength;
            vikings[i].tokenType = _type;
            _safeMint(_msgSender(), i);
            emit VikingSale(i, _msgSender(), mintDataType[_type].price);
        }
        TransferHelper.safeTransferFrom(address(saleToken), _msgSender(), feeReceiver, mintDataType[_type].price * _amount);
    }

    function mintByType(address _tokenOwner, uint256 _type) external onlyMinter checkTypeMint(_type, 1) {
        require(block.timestamp >= mintDataType[_type].startTime, "Vikings: Mint error, wrong time for type sale");
        uint256 newItemId = mintDataType[_type].currentSupply + mintDataType[_type].initialIndex;
        vikings[newItemId].birthTime = block.timestamp;
        vikings[newItemId].strength = mintDataType[_type].strength;
        vikings[newItemId].tokenType = _type;
        mintDataType[_type].currentSupply++;
        alreadyMintedAmount[_msgSender()]++;
        _safeMint(_tokenOwner, newItemId);
        emit VikingGenerated(newItemId, _tokenOwner);
    }

    function mintSupplyLeft(uint256 _type, uint256 _amount) external onlyOwner {
        require(totalTypes > _type, "Vikings: Error nonexistent type of mint");
        require(block.timestamp > mintDataType[_type].endTime, "Vikings: The sale is not over yet");
        uint256 indexToMint = mintDataType[_type].currentSupply + mintDataType[_type].initialIndex;
        uint256 amount = mintDataType[_type].totalSupply >= mintDataType[_type].currentSupply + _amount ? _amount : mintDataType[_type].totalSupply - mintDataType[_type].currentSupply;
        mintDataType[_type].currentSupply += amount;
        for (uint256 i = indexToMint; i < indexToMint + amount; i++) {
            vikings[i].birthTime = block.timestamp;
            vikings[i].strength = mintDataType[_type].strength;
            vikings[i].tokenType = _type;
            _safeMint(feeReceiver, i);
            emit VikingGenerated(i, feeReceiver);
        }
        alreadyMintedAmount[_msgSender()] += amount;
    }

    function lockToken(uint256 _tokenId, bool status) external onlyMinter {
        vikings[_tokenId].isLocked = status;
        emit VikingLocked(_tokenId, status);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = mintDataType[vikings[tokenId].tokenType].baseTokenUri;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal whenNotPaused override(ERC721Enumerable) {
        require(!vikings[tokenId].isLocked, "Vikings: Invalid transfer, the token is lock");
        super._beforeTokenTransfer(from, to, tokenId);
    }
}