pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract MyToken is owned {
	mapping (address => uint) public balanceOf;
	mapping (address => bool) public frozenAccount;
	string public name;
	string public symbol;
	uint8 public decimals;
	uint public totalSupply;
	uint256 public sellPrice;
    uint256 public buyPrice;
    uint minBalanceForAccounts;
	event Transfer(address indexed from, address indexed to, uint256 value);
	event FrozenFunds(address target, bool frozen);    

	function MyToken(
		uint256 _initialSupply, 
		string _tokenName, 
		string _tokenSymbol, 
		uint8 _decimalUnits,
		address _centralMinter
		) {
		if (_centralMinter != 0) owner = _centralMinter;
		totalSupply = _initialSupply;
		balanceOf[msg.sender] = _initialSupply;
		name = _tokenName;
		symbol = _tokenSymbol;
		decimals = _decimalUnits;		
	}

	function setMinBalance(uint minimumBalanceInFinney) onlyOwner {
         minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }

	function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable returns (uint amount){
        amount = msg.value / buyPrice;                    // calculates the amount
        require(balanceOf[this] >= amount);               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer's balance
        balanceOf[this] -= amount;                        // subtracts amount from seller's balance
        Transfer(this, msg.sender, amount);               // execute an event reflecting the change
        return amount;                                    // ends function and returns
    }

    function sell(uint amount) returns (uint revenue){
        require(balanceOf[msg.sender] >= amount);         // checks if the sender has enough to sell
        balanceOf[this] += amount;                        // adds the amount to owner's balance
        balanceOf[msg.sender] -= amount;                  // subtracts the amount from seller's balance
        revenue = amount * sellPrice;
        require(msg.sender.send(revenue));                // sends ether to the seller: it's important to do this last to prevent recursion attacks
        Transfer(msg.sender, this, amount);               // executes an event reflecting on the change
        return revenue;                                   // ends function and returns
    }

	function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }

    function freezeAccount(address _target, bool _freeze) onlyOwner {
    	frozenAccount[_target] = _freeze;
    	FrozenFunds(_target, _freeze);
    }

	// function transfer(address _to, uint256 _value) {
	// 	require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);
	// 	balanceOf[msg.sender] -= _value;
	// 	balanceOf[_to] += _value;
	// 	Transfer(msg.sender, _to, _value);
	// }

	/* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] > _value);                // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        if (msg.sender.balance < minBalanceForAccounts)
            sell((minBalanceForAccounts - msg.sender.balance) / sellPrice);
        Transfer(_from, _to, _value);
    }

}