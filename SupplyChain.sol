// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

contract Ownable {
    address public _owner;
    constructor() internal{
        _owner = msg.sender;
    }
    modifier onlyOwner() {
        require(isOwner() ,"you are not the owner");
        _;
    }
    function isOwner() public view returns(bool){
        return(msg.sender == _owner);

    }
}


contract Item {
    uint public priceInWei;
    uint public paidwei;
    uint public index;

    itemManager parentContract;
    constructor(itemManager _parentContract, uint _priceInWei, uint _index) public {
        priceInWei = _priceInWei;
        index = _index;
        parentContract = _parentContract;
    }
    receive()  external payable {
        require(msg.value == priceInWei,"partial payment done");
        require(paidwei == 0, "item is already paid");
        paidwei += msg.value;
        (bool success,) = address(parentContract).call{value:msg.value}(abi.encodeWithSignature("triggerPayment(uint256)", index));
        require(success,"delivery did not work");
    }
    fallback () external payable{

    }
}

contract itemManager is Ownable{
    enum supplyChainSteps{created, Paid, Delivered}

    struct S_item {
        Item _item;
        itemManager.supplyChainSteps _step;
        string _identifier;
        uint _priceInWei;
    }

    mapping(uint => S_item) public items;
    uint index;

    event supplyChainStep(uint _itemIndex, uint _step, address _address);


    function createItem(string memory _identifier, uint _priceInWei)  public onlyOwner {
        Item item = new Item(this, _priceInWei, index);
        items[index]._item = item;
        items[index]._priceInWei = _priceInWei;
        items[index]._step = supplyChainSteps.created;
        items[index]._identifier = _identifier;
        emit supplyChainStep( index, uint (items[index]._step), address(item));
        index++;

    }

    function triggerPayment(uint _index) public payable {
        Item item = items[_index]._item;
        require(items[_index]._priceInWei <= msg.value,"NOT FULLY PAID");
        require(items[_index]._step == supplyChainSteps.created,"THIS ITEM IS NOT YET IN SUPPLY CHAIN");
        items[_index]._step = supplyChainSteps.Paid;
        emit supplyChainStep(index, uint (items[index]._step), address(item));
        

    } 

    function triggerDelivery(uint _index) public onlyOwner{
        require(items[_index]._step == supplyChainSteps.Paid,"item is further in the supply chain");
        items[_index]._step = supplyChainSteps.Delivered;
        emit supplyChainStep(index,uint (items[index]._step), address(items[_index]._item));
    }
 }
