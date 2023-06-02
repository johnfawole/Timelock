 // SPDX-License-Identifier : MIT

  pragma solidity 0.8.19;
   
   import "https://github.com/binodnp/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol";
   import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";
   
   contract TimeLock {
     
     // this "locked" is a boolean variable we will use to checkmate reentrancy
     bool internal locked;
     
     // calling our libraries we imported into the contract
     using SafeERC20 for IERC20;
     using Safemath for uint256;
     
     // this is the address of the admin
     address payable public owner;
     // this is a boolean variable for contract owner access
     bool public allIncomingDepositsFinalized;

     // variables for timestamp
     uint256 public initialTimestamp;
     bool public timestampSet;
     uint256 public timePeriod;

     // amount management variables
     mapping(address => uint256) public alreadyWithdrawn;
     mapping(address => uint256) public balances;
     uint256 public contractBalance;
     
     // the contract address of the ERC20 token
     IERC20 public erc20Contract;

     constructor (IERC20 _erc_20_contract_address) {
         // set the erc20 address this contract will use
          require(address(_erc_20_contract_address) != 0, "cannot interact with address zero");
          erc20Contract = _erc_20_contract_address;

         owner = payable(msg.sender);
         
         // the lock should be false by default
         locked = false;

         // the timestamp is not yet set
         timestampSet = false;

         // the incoming deposits are not finalized by default
         allIncomingDepositsFinalized = false;
     }

        modifier noReentrancy() {
           require(!locked, "no reentrant");
           locked = true;
           _;
           locked = false;
     }

       modifier incomingDepositsStillAllowed () {
           require(allIncomingDepositsFinalized = false, "finalized already");
           _;
       }

      modifier onlyOwner () {
          require(msg.sender = owner, "only the owner");
          _;
      }

      modifier timestampNotSet () {
          require(timestampSet == false, "it has been set");
          _;
      }

      modifier timestampIsSet () {
          require(timestampSet == true, "kindly set the timestamp first");
          _;
      }

      // receive fallback for the intake of ether

      receive () payable external incomingDepositsStillAllowed {
        contractBalance = contractBalance.add(msg.value);
      }
      
      // this admin uses this function to allocate amounts to addresses
      // once finalize, the centralized admin influence stops and contract kicks off
      function finalizeAllIncomingDeposits () public onlyOwner timestampIsSet incomingDepositsStillAllowed {
        allIncomingDepositsFinalized = true;
      }

      function setTimestamp (_timePeriodInSeconds) public onlyOwner timestampNotSet {
        timestampSet = true;
        initialTimestamp = block.timestamp;
        timePeriod = initialTimestamp.add(_timePeriodInSeconds);
      }

      // @param we used "amount" to be more flexible
      // the admin can decide the amount to withdraw
      // can only allocate the assets one by one
      function withdraw (uint256 amount) public onlyOwner noReentrancy {
        require(amount <= contractBalance, "funds not sufficient");
        contractBalance = contractBalance.sub(amount);
      }

      function depositTokensToRecipients (address recipients, uint amount) public onlyOwner timestampIsSet incomingDepositsStillAllowed {
        require(recipient != address(0), "a zero address cannot receive");
        balances[recipients] = balances[recipient].add(amount);
      }

      function transferAccidentallySentTokens (uint256 amount, IERC20 token) public onlyOwner noReentrancy {
        require(address(token) != address(0), "no zero address should receive");
        require(token != erc20Contract, "already passed erc20 in the constructor, the accidental tokens should be something else");
        token.safeTransfer(owner, amount);
      }

      function transferLockedTokensAfterTimePeriod (IERC20 token, address receiver, uint256 amount) public timestampIsSet noReentrancy {
        require(address != address(0), "no zero address interaction");
        require(token == erc20Contract);
        require(msg.sender == receiver);
        require(balances[receiver] >= amount);


        if (block.timestamp >= timePeriod) {
            alreadyWithdrawn[receiver] = alreadyWithdrawn[receiver].add(amount);
            balances[receiver] = balances[receiver].sub(amount);
            token.safeTransfer(receiver, amount); 
        }    else {
            revert ("tokens are only available after timePeriod elapses");
        }
      }










   }
