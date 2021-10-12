// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

    address public owner;

    uint public skuCount;

    mapping(uint => Item) public items;

    enum State {
        ForSale, Sold, Shipped, Received
    }

    struct Item {
        string name;
        uint sku;
        uint price;
        State state;
        address payable seller;
        address payable buyer;
    }

    /*
     * Events
     */

    event LogForSale(uint sku);
    event LogSold(uint sku);
    event LogShipped(uint sku);
    event LogReceived(uint sku);

    /*
     * Modifiers
     */

    modifier isOwner(){
        require(owner == msg.sender, "User is not the owner of the contract");
        _;
    }

    modifier verifyCaller (address _address) {
        require(msg.sender == _address);
        _;
    }

    modifier paidEnough(uint _price) {
        require(msg.value >= _price);
        _;
    }

    modifier checkValue(uint _sku) {
        _;
        uint _price = items[_sku].price;
        uint amountToRefund = msg.value - _price;
        //     items[_sku].buyer.transfer(amountToRefund);
        //call is the current recommended method to use
        (bool success,) = items[_sku].buyer.call.value(amountToRefund)("");
    }

    modifier forSale(uint _sku){
        require(items[_sku].state == State.ForSale && items[_sku].seller != address(0), "Item is not for Sale");
        _;
    }
    modifier sold(uint _sku) {
        require(items[_sku].state == State.Sold);
        _;
    }

    modifier shipped(uint _sku){
        require(items[_sku].state == State.Shipped);
        _;
    }
    modifier received(uint _sku) {
        require(items[_sku].state == State.Received);
        _;
    }

    constructor() public {
        owner = msg.sender;
        // 2. Initialize the sku count to 0. Question, is this necessary? //No it is not, uint default value is 0.
        skuCount = 0;
    }

    function addItem(string memory _name, uint _price) public returns (bool) {
        items[skuCount] =
        Item({name : _name, sku : skuCount, price : _price, state : State.ForSale, seller : msg.sender, buyer : address(0)});
        skuCount += 1;
        emit LogForSale(skuCount);
        return true;
    }

    function buyItem(uint sku) public payable forSale(sku) paidEnough(items[sku].price) checkValue(sku) {
        Item storage item = items[sku];
        //using call instead of transfer cause is no longer recommended.
        (bool sent,) = item.seller.call.value(item.price)("");
        //    item.seller.transfer(item.price);
        item.buyer = msg.sender;
        item.state = State.Sold;
        emit LogSold(sku);
    }

    function shipItem(uint sku) public sold(sku) verifyCaller(items[sku].seller) {
        items[sku].state = State.Shipped;
        emit LogShipped(sku);
    }

    function receiveItem(uint sku) public shipped(sku) verifyCaller(items[sku].buyer) {
        items[sku].state = State.Received;
        emit LogReceived(sku);
    }

    function fetchItem(uint _sku) public view
    returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
    {
        name = items[_sku].name;
        sku = items[_sku].sku;
        price = items[_sku].price;
        state = uint(items[_sku].state);
        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
        return (name, sku, price, state, seller, buyer);
    }
}
