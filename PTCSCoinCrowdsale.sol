pragma solidity ^0.4.18;

import './Ownable.sol';
import './SafeMath.sol';
import './PTCSCoin.sol';
import './RefundVault.sol';

contract PTCSCoinCrowdsale is Ownable {
  using SafeMath for uint256;

  PTCSCoin public token;

  uint256 public startTime;
  uint256 public endTime;
  uint256 public periodB;
  uint256 public periodC;
  uint256 public periodD;
  uint256 public periodE;
  uint256 public periodF;

  uint256 public reward;
  uint256 public ownToken;
  uint256 public buyToken; 

  uint public minPurchase;
  uint exchangeStage1;
  uint exchangeStage2;
  uint exchangeRate;
  
  bool public isFinalized = false;

  uint256 public totalToken;
  uint256 public goal;
  uint256 public tokenSaled = 0;
  address _token;

  RefundVault public vault;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event Finalized();
  event Withdraw(address to, uint value);

  function PTCSCoinCrowdsale() public {
      _token = 0x398e5cc005e644688484d1c1844d09de47918011;
    require(_token != address(0));
    vault = new RefundVault();
    token = PTCSCoin(_token);
    startTime = 1548432000;                 //2019/1/26 00:00:00
    endTime = 1558800000;                   //2019/5/26 00:00:00
    periodB = 1548432000;                   //2019/1/26 00:00:00
    periodC = 1551110400;                   //2019/2/26 00:00:00
    periodD = 1553529600;                   //2018/3/26 00:00:00
    periodE = 1556208000;                   //2018/4/26 00:00:00
    periodF = 1558800000;                   //2018/5/26 00:00:00
    
    require(endTime >= now);
    minPurchase = 0.5 ether; 
    exchangeRate = 5600;
    totalToken = 700000000 * 10 ** uint256(token.decimals());
    
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;
    buyToken = weiAmount;

    // calculate token amount to be created
    uint256 buytokens;
    uint256 rewardTokens;
    if(now>=periodB && now<periodC){
         buytokens = weiAmount.mul(exchangeRate);
         rewardTokens=buytokens.mul(45);
         rewardTokens=rewardTokens.div(100);
    }else if(now>=periodC && now<periodD){
         buytokens = weiAmount.mul(exchangeRate);
         rewardTokens=buytokens.mul(35);
         rewardTokens=rewardTokens.div(100);
    }else if(now>=periodD && now<periodE){
         buytokens = weiAmount.mul(exchangeRate);
         rewardTokens=buytokens.mul(40);
         rewardTokens=rewardTokens.div(100);
    }else if(now >= periodE && now < periodF){
         buytokens = weiAmount.mul(exchangeRate);
         rewardTokens=buytokens.mul(25);
         rewardTokens=rewardTokens.div(100);
    }
    ownToken = buytokens;
    reward = rewardTokens;
    
    uint256 alltokens = buytokens + rewardTokens;
    require(alltokens <= totalToken - tokenSaled);

    // update state
    tokenSaled = tokenSaled.add(alltokens);

    token.transfer(beneficiary, buytokens);
    token.transferToLockedBalance(beneficiary,rewardTokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, alltokens);

    forwardFunds();
  }

  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    token.transfer(owner,token.balanceOf(this));

    isFinalized = true;
  }
  
  function claimRefund() public {
    require(isFinalized);
    vault.refund(msg.sender);
  }

  function withdraw(address to, uint value) onlyOwner public {
    vault.withdraw(to,value);
    Withdraw(to,value);
  }
  
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

 

  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }
  
  function validPurchase() internal view returns (bool) {
    bool withinStart = now >= startTime;
    bool withinPeriod = now < endTime;
    bool purchaseAmount = msg.value >= minPurchase;
    bool recruitAmount = tokenSaled < totalToken;
    return withinPeriod && purchaseAmount && recruitAmount && withinStart;
  }

  function finalization() internal {
  
      vault.close();
    
  }
}