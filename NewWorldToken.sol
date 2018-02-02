pragma solidity ^0.4.11;
import './SafeMath.sol';
import './ERC20Token.sol';

contract SimpleCrowdSale is ERC20Token {

    string public constant version = "0.1";

    bool public funding = true; // funding state

    uint256 public tokenContributionRate = 7000; // how many tokens one QTUM equals
    uint256 public tokenContributionCap = 4000000000 * 100000000; // max amount raised during crowdsale
    uint256 public tokenContributionMin = 3000000000 * 100000000; // min amount raised during crowdsale

    uint8 public founderPercentOfTotal = 60; // should between 0 to 99
    address public founder = 0x0; // the contract creator's address

    // triggered when this contract is deployed
    event ContractCreated(address _this);
    // triggered when contribute successful
    event Contribution(address indexed _contributor, uint256 _amount, uint256 _return);
    // triggered when refund successful
    event Refund(address indexed _from, uint256 _value);
    // triggered when crowdsale is over
    event Finalized(uint256 _time);

    modifier validAmount(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // 设定ICO的 开始时间、持续时间、汇率、最小目标、最大目标、代币名称、符号
    function SimpleCrowdSale()
        ERC20Token("NewWorldToken", "NWT", 8)
    {
        founder = msg.sender;
        ContractCreated(address(this));
    }

    function ()
        payable
    {
        contribute();
    }


    function contribute()
        public
        payable
        validAmount(msg.value)
        returns (uint256 amount)
    {
        assert(totalSupply < tokenContributionCap);

        //阶梯价格
        if(totalSupply>=3000000000 * 100000000) {
            tokenContributionRate = 7000;
        }else if(totalSupply>=2000000000 * 100000000) {
            tokenContributionRate = 7777;
        }else if(totalSupply>=1000000000 * 100000000) {
            $tokenContributionRate = 8750;
        }else if(totalSupply>=0) {
            $tokenContributionRate = 10000;
        }

        uint256 tokenAmount = safeMul(msg.value, tokenContributionRate);
        uint back_qtum = 0;

        if (safeAdd(totalSupply, tokenAmount) > tokenContributionCap) {
            uint over = safeAdd(totalSupply, tokenAmount) - tokenContributionCap;
            back_qtum = over/tokenContributionRate;
            tokenAmount = tokenContributionCap - totalSupply;
        }

        totalSupply = safeAdd(totalSupply, tokenAmount);
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], tokenAmount);
        Contribution(msg.sender, msg.value, tokenAmount);
        if (back_qtum > 0) {
            msg.sender.transfer(back_qtum);
        }
        return tokenAmount;
    }


    function finalize()
        public
    {
        assert(funding);
        assert(totalSupply >= tokenContributionMin);

        funding = false;
        uint256 additionalTokens =
            safeMul(totalSupply, founderPercentOfTotal) / (100 - founderPercentOfTotal);
        totalSupply = safeAdd(totalSupply, additionalTokens);
        balanceOf[founder] = safeAdd(balanceOf[founder], additionalTokens);
        Transfer(0, founder, additionalTokens);
        Finalized(now);
        founder.transfer(this.balance);
    }

}
