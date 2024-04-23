// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';

YO
/**
 * @title Stake eth to earn rewards
 * @notice rewards are also earned in eth
 */

contract StakingPool is Context,ReentrancyGuard, Ownable {

  /**PUBLIC VARIABLES */
  using SafeERC20 for IERC20;
  uint256 constant MULTIPLIER = 10 ** 36;
  // address internal token;
  uint256 public lockPeriod_1=20 days;
  uint256 public lockPeriod_2=40 days;
  uint256 public lockPeriod_3=60 days;
  uint256 internal totalStakedUsers;
  uint256 internal totalSharesDepositedInETH;
  uint256 internal rewardsPerShare_1;
  uint256 internal rewardsPerShare_2;
  uint256 internal rewardsPerShare_3;


  /**STRUCTS */
  struct Share {
    uint256 amount;
    uint256 stakeType;
    uint256 stakedTimeStamp;
  }
  struct Reward {
    uint256 excluded;
    uint256 realised;
  }

  struct Bank {
    uint256 totalDistributed;
    uint256 totalRewards_1;
    uint256 totalRewards_2;
    uint256 totalRewards_3;
  }

  Bank public bank;

  /**MAPPINGS */
  mapping(address => Share) public shares; 
  mapping(address => Reward) public rewards;

  /**EVENTS */
  event Stake(address indexed user, uint256 amount);
  event Unstake(address indexed user, uint256 amount);
  event ClaimReward(address user);
  event DepositRewards(address indexed user, uint256 amountTokens);
  event DistributeReward(
    address indexed user,
    uint256 amount,
    bool _wasCompounded
  );

  constructor()Ownable(msg.sender) {
  }

  function stake(uint256 _stakeType) external nonRee payable  {

    // IERC20(token).safeTransferFrom(_msgSender(), address(this), _amount);
    // IERC20(token).safeIncreaseAllowance(address(this),_amount);
    _setShare(_msgSender(), msg.value,_stakeType, false);
  }
  /**
   * @notice allows user to stake ETH into the contract
   * @dev calls the _setShare(isRemoving? false) function which in turn calls _addShare function
   * @dev if already staked, _addShares calls _distributeRewards
   * @dev _addShares increments totalSharesDepositedInETH
   * @dev _addShares updates user struct(stakeType, amount and timestamp)
   * @dev if new user, _addshares increments totalStakedUsers
   * @dev _addShares  calculates _cumulativeRewards and adds that to exclueded rewards for that user
   */

  function stakeForWallets(
    address[] memory _wallets,
    uint256[] memory _amounts,
    uint256 stakeType
  ) external  {
    require(_wallets.length == _amounts.length, 'INSYNC');
    uint256 _totalAmount;
    for (uint256 _i; _i < _wallets.length; _i++) {
      _totalAmount += _amounts[_i];
      _setShare(_wallets[_i], _amounts[_i],stakeType, false);
    }
    // IERC20(token).safeTransferFrom(_msgSender(), address(this), _totalAmount);
  }

  function unstake(uint256 _amount) external{
    require(_amount<shares[msg.sender].amount,"enter valid amount");
    uint256 _stakeType=shares[msg.sender].stakeType;
    bool success=payable(msg.sender).send(_amount);
    require(success,"transfer failed");
    // IERC20(token).safeTransfer(_msgSender(), _amount);
    _setShare(_msgSender(), _amount,_stakeType, true);
  }
  /**
   * @notice allows user to unstake their staked ETH
   * @dev transfers unstake amount to user's wallet
   * @dev then calls _setShare(isRemoving? true) which calls _removeShares
   * @dev _removeShares calls getUnpaid function to fetch(excluded rewards - realised rewards) 
   * @dev if no user remains after unstaking, _removeShares distributes rewards to calling user
   * @dev _removeShares decrements totalSharesDepositedInETH and user share amount in share struct
   * @dev if user unstakes all his ETH, _removeShares decrements totalStakedUsers
   * @dev updates excluded rewards for that user = cumulative rewards
   */

  function _setShare(
    address wallet,
    uint256 balanceUpdate,
    uint256 stakeType,
    bool isRemoving
  ) internal {

    if (isRemoving) {
      _removeShares(wallet, balanceUpdate,stakeType);
      emit Unstake(wallet, balanceUpdate);
    } else {
      _addShares(wallet, balanceUpdate,stakeType);
      emit Stake(wallet, balanceUpdate);
    }
  }
  /**
   * @notice adds or removes shares
   * @dev called by stake or unstake function above
   */

  function _addShares(address wallet, uint256 amount,uint256 stakeType) private {
    if (shares[wallet].amount > 0) {
      _distributeReward(wallet, false,stakeType);
    }
    uint256 sharesBefore = shares[wallet].amount;
    totalSharesDepositedInETH += amount;
    shares[wallet].amount += amount;
    shares[wallet].stakeType = stakeType;
    shares[wallet].stakedTimeStamp = block.timestamp;
    if (sharesBefore == 0 && shares[wallet].amount > 0) {
      totalStakedUsers++;
    }
    rewards[wallet].excluded = _cumulativeRewards(shares[wallet].amount,stakeType);
  }
  /**
   * @notice adds shares to account
   * @dev see stake function natspec for flow
   */

  function _removeShares(address wallet, uint256 amount,uint256 stakeType) private {
    require(
      shares[wallet].amount > 0 && amount <= shares[wallet].amount,
      'REM: amount'
    );
    if(stakeType==1){    
      require(
      block.timestamp > shares[wallet].stakedTimeStamp + lockPeriod_1,
      'REM: timelock'
    );}
    else if(stakeType==2){    
      require(
      block.timestamp > shares[wallet].stakedTimeStamp + lockPeriod_2,
      'REM: timelock'
    );}
    else if(stakeType==3){    
      require(
      block.timestamp > shares[wallet].stakedTimeStamp + lockPeriod_3,
      'REM: timelock'
    );}

    uint256 _unclaimed = getUnpaid(wallet,stakeType);
    bool _otherStakersPresent = totalSharesDepositedInETH - amount > 0;
    if (!_otherStakersPresent) {
      _distributeReward(wallet, false,stakeType);
    }
    totalSharesDepositedInETH -= amount;
    shares[wallet].amount -= amount;
    if (shares[wallet].amount == 0) {
      totalStakedUsers--;
    }
    rewards[wallet].excluded = _cumulativeRewards(shares[wallet].amount,stakeType);
    // if there are other stakers and unclaimed rewards,
    // deposit them back into the pool for other stakers to claim
    if (_otherStakersPresent && _unclaimed > 0) {
      _depositRewards(wallet, _unclaimed);
    }
  }
  /**
   * @notice removes shares from the pool
   * @dev see unstake function natspec for flow
   */

  function depositRewards() external payable {
    _depositRewards(_msgSender(), msg.value);
  }
  /**
   * @notice investor can deposit rewards into the contract in ETH
   * @dev this function calls _depositRewards function
   */

  function _depositRewards(address _wallet, uint256 _amountETH) internal {
    uint256 amt= (_amountETH*25)/100;
    //transfer this to reserve
    require(_amountETH > 0, 'ETH');
    require(totalSharesDepositedInETH > 0, 'SHARES');
    bank.totalRewards_1 += (_amountETH*10)/100;
    bank.totalRewards_2 += (_amountETH*25)/100;
    bank.totalRewards_3 += (_amountETH*40)/100;
    rewardsPerShare_1 += (MULTIPLIER * bank.totalRewards_1) / totalSharesDepositedInETH;
    rewardsPerShare_2 += (MULTIPLIER * bank.totalRewards_2) / totalSharesDepositedInETH;
    rewardsPerShare_3 += (MULTIPLIER * bank.totalRewards_3) / totalSharesDepositedInETH;
    emit DepositRewards(_wallet, _amountETH);
  }
  /**
   * @notice deposit rewards called by depositRewards above
   */

  function _distributeReward(
    address _wallet,
    bool _compound,
    uint256 _stakeType

  ) internal {
    if (shares[_wallet].amount == 0) {
      return;
    }
    shares[_wallet].stakedTimeStamp = block.timestamp; // reset every claim
    uint256 _amountWei = getUnpaid(_wallet,_stakeType);
    rewards[_wallet].realised += _amountWei;
    rewards[_wallet].excluded = _cumulativeRewards(shares[_wallet].amount, _stakeType);
    if (_amountWei > 0) {
      bank.totalDistributed += _amountWei;
      if (_compound) {
        autostake(_wallet, _amountWei,_stakeType);
      } else {
        uint256 _balBefore = address(this).balance;
        (bool success, ) = payable(_wallet).call{ value: _amountWei }('');
        require(success, 'DIST0');
        require(address(this).balance >= _balBefore - _amountWei, 'DIST1');
      }
      emit DistributeReward(_wallet, _amountWei, _compound);
    }
  }
  /**
   * @notice distribute rewards for the user
   * @dev calculations are explained in stake/unstake
   */

  function autostake(
    address _wallet,
    uint256 _wei,
    uint256 _stakeType
   
  ) internal {
   

    totalSharesDepositedInETH+=_wei ;
    shares[msg.sender].amount+=_wei;
    // _router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: _wei }(
    //   _minTokensToReceive,
    //   path,
    //   address(this),
    //   block.timestamp
    // );
    
    _setShare(_wallet, _wei,_stakeType, false);
  }
  /**
   * @notice autostake user's ETH rewards
   */

  function claimReward(
    bool _compound,
    uint256 _stakeType
     
  ) external {
    _distributeReward(_msgSender(), _compound,_stakeType);
    emit ClaimReward(_msgSender());
  }
  /**
   * @notice called by the user, uset to deposit current rewards in the wallet
   */

  function claimRewardAdmin(
    address _wallet,
    bool _compound,
    uint256 _stakeType
  ) external onlyOwner {
    _distributeReward(_wallet, _compound, _stakeType);
    emit ClaimReward(_wallet);
  }
  /**
   * @notice used to manually transfer rewards to th user's wallet by the owner
   */

  /**CONTRACT GETTER FUNCTIONS */
  function getUnpaid(address wallet,uint256 stakeType) internal view returns (uint256) {
    if (shares[wallet].amount == 0) {
      return 0;
    }
    uint256 earnedRewards = _cumulativeRewards(shares[wallet].amount, stakeType);
    uint256 rewardsExcluded = rewards[wallet].excluded;
    if (earnedRewards <= rewardsExcluded) {
      return 0;
    }
    return earnedRewards - rewardsExcluded;
  }
  /**
   * @notice calculates rewards realised-rewards excluded
   * @return uint256 rewards
   */

  function _cumulativeRewards(uint256 share,uint256 stakeType) internal view returns (uint256) {
    if(stakeType==1){
        return (share * rewardsPerShare_1) ;} // / MULTIPLIER
    else if(stakeType==2){
        return (share * rewardsPerShare_2) ;} // / MULTIPLIER
    else if(stakeType==3){
        return (share * rewardsPerShare_3) ;} // / MULTIPLIER
  }
  /**
   * @notice calculates share*rewardRate
   * @return uint256 cumulative rewards
   */

  /**ADMIN GETTER FUNCTIONS */
  function getTotalStakedUsers() public onlyOwner view  returns(uint256){
    return totalStakedUsers;
  }
  /**
   * @return uint256 total staked users
   * @dev owner only
   */

   function getTotalShares() public onlyOwner view returns(uint256){
    return totalStakedUsers;
   }
   /**
   * @return uint256 total shares deposited in ETH
   * @dev owner only
   */

    function rewardRate(uint256 typ) public onlyOwner view returns(uint256){
     if(typ==1){
        return rewardsPerShare_1;
     }
     else if(typ==2){
        return rewardsPerShare_2;
     }
     else if(typ==2){
        return rewardsPerShare_3;
     }
   }
   /**
   * @return uint256 reward rate
   * @dev owner only
   */
}