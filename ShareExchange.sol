pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract ShareExchange {
    ShareExchangeData m_data;
    ShanWooToken m_erc20;

    constructor(ShareExchangeData data, ShanWooToken erc20) public
    {
        m_data = data;
        m_erc20 = erc20;
    }

    function depositShare(address depositTo, uint depositNums, uint requireTokens, bytes32 proofHash, string proofFileUrl) public returns(bool success, bytes32 exchangeId) {
        exchangeId = keccak256(toBytes(block.timestamp));

        success = m_data.set(
            exchangeId,
            false,
            tx.origin,
            depositTo,
            depositNums,
            requireTokens,
            proofHash,
            proofFileUrl
        );

        if (!success)
            return (false, exchangeId);

        emit DepositShare(
            exchangeId, 
            tx.origin, 
            depositTo, depositNums, requireTokens, proofHash, proofFileUrl);
    }
    function purchaseShare(bytes32 exchangeId) public returns (bool success){
        bool isDirty;
        bool enabled;
        address from;
        address to;
        uint depositNums;
        uint requireTokens;

        (enabled, 
        from, 
        to,
        depositNums,
        requireTokens,
        ,
        ,
        isDirty) = m_data.get(exchangeId);

        if (tx.origin != to)
            return false;
        
        if (!isDirty || enabled) 
            return false;

        uint fromBalance = m_erc20.balanceOf(to);
        if (fromBalance < requireTokens)
            return false;

        bool transferSuccess = m_erc20.transfer(from, requireTokens);
        
        if (!transferSuccess)
            return false;
        
        bool enableSuccess = m_data.enableShare(exchangeId);
        if (!enableSuccess)
            return false;

        emit PurchaseShare(exchangeId, from, to, depositNums, requireTokens);
    }
    function depositInfo(bytes32 exchangeId) public constant returns (bool hasPurchase, address from, address to, uint depositNums, uint requireTokens, bytes32 proofHash, string proofFileUrl)
    {
        bool isDirty;
        bool enabled;
        (enabled, 
        from, 
        to,
        depositNums,
        requireTokens,
        proofHash,
        proofFileUrl,
        isDirty) = m_data.get(exchangeId);
        hasPurchase = !isDirty && enabled;
    }

    function enableData() public returns (bool success)
    {
        address newOwner = m_data.newOwner();
        address local = this;
        if (newOwner == local)
        {
            m_data.acceptOwnership();
            return true;
        }
        else
            return false;

    }

    function toBytes(uint256 x) private pure returns (bytes b) 
    {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x)}
    }

    event DepositShare(bytes32 exchangeId, address depositFrom, address depositTo, uint depositNums, uint requireTokens, bytes32 proofHash, string proofFileUrl);
    event PurchaseShare(bytes32 exchangeId, address depositFrom, address depositTo, uint depositNums, uint requireTokens);
}


