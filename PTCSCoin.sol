pragma solidity ^0.4.18;

import './Ownable.sol';
import './Pausable.sol';
import './SafeMath.sol';

contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

contract PTCSCoin is Pausable, DetailedERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  mapping(address => uint256) public lockedBalances;

  uint public unlocktime;
  address crowdsaleContract = 0;

  function PTCSCoin() DetailedERC20("PTCS.io", "PTCS", 18) public {
    unlocktime = 1564070400;                              // 2019/7/26 00:00:00
    totalSupply = 1800000000 * 10 ** uint256(decimals);
    balances[msg.sender] = totalSupply;
  }

  function setCrowdsaleContract(address crowdsale) onlyOwner public {
    crowdsaleContract = crowdsale;
  }

  modifier timeLock(address from, uint value) { 
    if (now < unlocktime) {
      require(value <= balances[from] - lockedBalances[from]);
    } else {
      lockedBalances[from] = 0;
    }
    _;
  }

  function transfer(address _to, uint256 _value) timeLock(msg.sender, _value) whenNotPaused public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferToLockedBalance(address _to, uint256 _value) whenNotPaused public returns (bool) {
    require(msg.sender == crowdsaleContract);
    if (transfer(_to, _value)) {
      lockedBalances[_to] = lockedBalances[_to].add(_value);
      return true;
    }
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }


  function transferFrom(address _from, address _to, uint256 _value) public timeLock(_from, _value) whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}