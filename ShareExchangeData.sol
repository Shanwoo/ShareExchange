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

contract ShareExchangeData is Owned {
    event SetShareExchange(        
        bytes32 exchangeId,
        bool enabled, 
        address shareOwner, 
        address shareTo,
        uint shareNums,
        uint requireTokens,
        bytes32 proofHash,
        string proofFileUrl,
        bool isDirty
    );
    
    event EnableShare(bytes32 exchangeId, bool enabled);

    struct Share {
        bool enabled;
        address shareOwner;
        address shareTo;
        uint shareNums;
        uint requireTokens;
        bytes32 proofHash;
        string proofFileUrl;
        bool isDirty; // Determine if the share has been initralized
    } 
    
    mapping(bytes32 => Share) m_shares;
    
    function get(bytes32 exchangeId) 
        public view 
        returns (
            bool enabled, 
            address shareOwner, 
            address shareTo,
            uint shareNums,
            uint requireTokens,
            bytes32 proofHash,
            string proofFileUrl,
            bool isDirty
        ) 
    {
        Share memory s = m_shares[exchangeId];
        enabled = s.enabled;
        shareOwner = s.shareOwner;
        shareTo = s.shareTo;
        shareNums = s.shareNums;
        requireTokens = s.requireTokens;
        proofHash = s.proofHash;
        proofFileUrl = s.proofFileUrl;
        isDirty = s.isDirty;
    }

    function set(
        bytes32 exchangeId,
        bool enabled, 
        address shareOwner, 
        address shareTo,
        uint shareNums,
        uint requireTokens,
        bytes32 proofHash,
        string proofFileUrl
        ) 
        public onlyOwner
        returns (bool success)
    {
        Share memory s = m_shares[exchangeId];

        if (s.isDirty && s.shareOwner != tx.origin)
            return false;

        s.enabled = enabled;
        s.shareOwner = shareOwner;
        s.shareTo = shareTo;
        s.shareNums = shareNums;
        s.requireTokens = requireTokens;
        s.proofHash = proofHash;
        s.proofFileUrl = proofFileUrl; 
        s.isDirty = true; 
        m_shares[exchangeId] = s;  
        emit SetShareExchange(
            exchangeId, 
            s.enabled, 
            s.shareOwner, 
            s.shareTo, 
            s.shareNums, 
            s.requireTokens, 
            s.proofHash, 
            s.proofFileUrl, 
            s.isDirty
        );
        return true;   
    }

    function enableShare(bytes32 exchangeId) public onlyOwner returns (bool success)
    {
        Share memory s = m_shares[exchangeId];
        if (!s.isDirty || s.enabled)
            return false;
        s.enabled = true;
        m_shares[exchangeId] = s;
        emit EnableShare(exchangeId, m_shares[exchangeId].enabled);
        return true;
    }
}
