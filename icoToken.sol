// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract TDNetwork{
mapping(address => uint) public balances;
mapping(address => mapping(address => uint)) public allowance;
uint public totalSupply = 120000000 * 10 ** 18; //120million total supply with 18 decimals
string public name = "TD Network";
string public symbol = "TDIS";
uint public decimals = 18; //18 decimal places
event Transfer(address indexed from, address indexed to, uint value);
event Approval(address indexed owner, address indexed spender, uint value);
constructor() {
balances[msg.sender] = totalSupply; //send total minted tokens to the contract creator
}
function balanceOf(address owner) public view returns(uint) {
return balances[owner];
}
function transfer(address to, uint value) public returns(bool) { //transfer token function
require(balanceOf(msg.sender) >= value, 'balance too low');
balances[to] += value;
balances[msg.sender] -= value;
emit Transfer(msg.sender, to, value);
return true;
}
function transferFrom(address from, address to, uint value) public returns(bool) {
require(balanceOf(from) >= value, 'balance too low');
require(allowance[from][msg.sender] >= value, 'allowance too low');
balances[to] += value;
balances[from] -= value;
emit Transfer(from, to, value);
return true;
}
function approve(address spender, uint value) public returns (bool) {
allowance[msg.sender][spender] = value;
emit Approval(msg.sender, spender, value);
return true;
}
}


contract CrowdSale is TDNetwork{
    address public admin;//address that can stop crowdsale
    address payable public deposit; //the address that takes in the investors crypto
    uint tokenPrice = 0.0002 ether;///1 ETH = 5000 TDIS
    uint public hardCap = 2000 ether; //2000 ETH Hard Cap
    uint public raisedAmount; //total amount raised
    uint public saleStart = block.timeStamp; //starts when contract is created
    uint public saleEnd = block.timestamp + 604800;//ends in a week of the contract creation
    uint public minInvestment = 0.1 ether;//min investment 0.1 eth

    enum State { beforeStart, running, afterEnd, halted} //ICO states
    State public icoState;

    constructor(address payable _deposit){
        deposit = _deposit;//where the eth will be transferred. can be hardcoded
        admin = msg.sender;//can be the same address as deposit address. can also be hardcoded
        icoState = State.beforeStart;
    }

    modifier onlyAdmin(){
        require(msg.sender==admin);
        _;  //admin (contract creator is the only one who can change states (unless done directly through contract code such as when ICO ends)
    }
    function halt() public onlyAdmin{
        icoState = State.halted;//ICO paused
    }

    function resume() public onlyAdmin{
        icoState = State.running; //ICO running
    }

    function changeDepositAddress(address payable newDeposit) public onlyAdmin{
        deposit = newDeposit; //change address of where the ETH is deposited
    }

    function getCurrentState() public view returns(State){
        if(icoState == State.halted){
            return State.halted;
        } else if (block.timestamp < saleStart){
            return State.beforeStart;
        } else if (block.timestamp > saleStart && block.timestamp <= saleEnd){
            return State.running;
        } else {
            return State.afterEnd;
        }
    }

    event Invest(address investor, uint value, uint tokens);

    function invest() payable public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.running);//investors can only invest when ICO state is 'running'

        require(msg.value >= minInvestment);//has to be atleast min investment
        raisedAmount += msg.value;
        require(raisedAmount <= hardCap);//total tokens sold must be less than hardcap

        uint tokens = msg.value / tokenPrice;

        balances[msg.sender] += tokens;//send token to buyer
        balances[owner] -= tokens;//take away token from seller
        deposit.transfer(msg.value);
        emit invest(msg.sender, msg.value, tokens);
        return true;
    }

    receive() payable external{
        invest();
    }

}
