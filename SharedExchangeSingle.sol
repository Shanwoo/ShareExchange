
pragma solidity ^0.4.24;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract ShareExchange is Owned {

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

    function depositShare(address depositTo, uint depositNums, uint requireTokens, bytes32 proofHash, string proofFileUrl) public returns(bool success, bytes32 exchangeId) {
        exchangeId = keccak256(toBytes(block.timestamp));

        Share memory s = m_shares[exchangeId];

        if (s.enabled || s.isDirty && s.shareOwner != msg.sender)
            return (false, bytes32());

        s.enabled = false;
        s.shareOwner = msg.sender;
        s.shareTo = depositTo;
        s.shareNums = depositNums;
        s.requireTokens = requireTokens;
        s.proofHash = proofHash;
        s.proofFileUrl = proofFileUrl; 
        s.isDirty = true; 

        m_shares[exchangeId] = s;  

        emit DepositShare(
            exchangeId, 
            msg.sender, 
            depositTo, depositNums, requireTokens, proofHash, proofFileUrl);
        return (false, exchangeId);
    }
    function purchaseShare(bytes32 exchangeId) public returns (bool success){
        Share memory s = m_shares[exchangeId];

        if (!s.isDirty)
            return false;

        if (s.enabled)
            return false;

        if (s.shareTo != msg.sender)
            return false;
        
        if (balanceOf(msg.sender) < s.requireTokens)
            return false;
        
        transfer(s.shareOwner, s.requireTokens);

        s.enabled = true;
        m_shares[exchangeId] = s;

        emit PurchaseShare(exchangeId, s.shareOwner, msg.sender, s.depositNums, s.requireTokens);
        return true;
    }
    function depositInfo(bytes32 exchangeId) public constant returns (bool hasPurchase, address from, address to, uint depositNums, uint requireTokens, bytes32 proofHash, string proofFileUrl)
    {
        Share memory s = m_shares[exchangeId];

        return (
            s.enabled,
            s.shareOwner,
            s.shareTo,
            s.shareNums,
            s.requireTokens,
            s.proofHash,
            s.proofFileUrl
        );
    }

    function toBytes(uint256 x) private pure returns (bytes b) 
    {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x)}
    }

    event DepositShare(bytes32 exchangeId, address depositFrom, address depositTo, uint depositNums, uint requireTokens, bytes32 proofHash, string proofFileUrl);
    event PurchaseShare(bytes32 exchangeId, address depositFrom, address depositTo, uint depositNums, uint requireTokens);
}

