pragma solidity ^0.6.0;

contract Ownable {
    address payable owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(isOwner(), "You are not the owner");
        _;
    }
    
    function isOwner() public view returns(bool) {
        return msg.sender == owner;
    }
}

contract ItemContract {
    
    uint public index;
    uint public price;
    uint public paidPrice;
    
    ItemManager parentContract;
    
    constructor(ItemManager _parentContract, uint _index, uint _price) public {
        price = _price;
        index = _index;
        parentContract = _parentContract;
    }
    
    receive() external payable {
        require(paidPrice == 0, "Item is already paid.");
        require(price == msg.value, "Only full payments allowed.");
        
        paidPrice = msg.value;
        
        (bool success,) = address(parentContract).call.value(msg.value)(abi.encodeWithSignature("triggerPaymentEvent(uint256)", index));
        require(success, "The transaction was not successful, canceling.");
    }
    
    fallback() external{}
}

contract ItemManager is Ownable{
    
    event ItemEvent(uint itemIndex, uint step, address itemAddress);
    
    enum ItemState{Created, Paid, Delivered}
    
    struct Item {
        string id;
        uint price;
        ItemState state;
        
        ItemContract item;
    }
    
    mapping( uint => Item) public items;

    uint itemIndex;
    
    function createItem(string memory _id, uint _price) public onlyOwner {
        ItemContract item = new ItemContract(this, itemIndex, _price);
        
        items[itemIndex].item = item;
        items[itemIndex].id = _id;
        items[itemIndex].price = _price;
        items[itemIndex].state = ItemState.Created;
        
        emit ItemEvent(itemIndex, uint(items[itemIndex].state), address(item));
        
        itemIndex++;
    }
    
    function triggerPaymentEvent(uint _itemIndex) public payable onlyOwner {
        require(items[_itemIndex].price == msg.value, "Only full payments accepted");
        require(items[_itemIndex].state == ItemState.Created, "Item is not availaby anymore");
        items[_itemIndex].state = ItemState.Paid;
        
        emit ItemEvent(_itemIndex, uint(items[_itemIndex].state), address(items[_itemIndex].item));
    }
    
    function triggerDeliveryEvent(uint _itemIndex) public {
        require(items[_itemIndex].state == ItemState.Paid, "Item is not availaby anymore");
        items[_itemIndex].state = ItemState.Delivered;
        
        emit ItemEvent(itemIndex, uint(items[itemIndex].state), address(items[_itemIndex].item));
    }
}