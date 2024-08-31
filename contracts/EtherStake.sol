// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract EtherStake{
    uint256 constant public MAX_DURATION = 60; //in days
    uint256 constant public DAYS_IN_YEAR = 365;
    uint256 constant public FIXED_RATE = 10;

    struct StakersDetails{
        uint startTime;
        uint256 endTime;
        uint256 expectedInterest;
        uint amount;
        bool deposited;
    }

    StakersDetails[] details;

    mapping(address => StakersDetails[]) public stakers;

    function addStackers() external payable {
        require(msg.sender != address(0), "Address zero detected");
        require(msg.value > 0, "AMOUT MUST BE GREATER THAN ZERO");
        //Calculating the end time
        uint256 startStaking = block.timestamp + 1;
        StakersDetails memory newStakes = StakersDetails(
            {
                startTime: startStaking,
                endTime: block.timestamp + MAX_DURATION,
                expectedInterest: calculateInterest(msg.value, FIXED_RATE, MAX_DURATION),
                amount: msg.value,
                deposited: true
            }
        );

        details.push(newStakes);
        stakers[msg.sender] = details;
    }


        function claimReward(address _address, uint256 _index) external payable {
        require(stakers[_address][_index].expectedInterest > 0, "No valid stake at the selected index");
        StakersDetails storage selectedStake = stakers[_address][_index];
        require(block.timestamp > selectedStake.endTime, "Stake is still ongoing");
        require(!selectedStake.deposited, "Stake already completed");
        require(address(this).balance >= selectedStake.expectedInterest, "Contract does not have enough funds");
        selectedStake.deposited = true;
        (bool success,) = msg.sender.call{value: selectedStake.expectedInterest}("");
        require(success, "Reward transfer failed");
    }

    function showCurrentInterest(uint256 _index) view public returns(uint){
        StakersDetails storage selectedStake = stakers[msg.sender][_index];
        return selectedStake.expectedInterest;
    }
    

    function getAllUserStakes(address _address) external view returns (StakersDetails[] memory) {
        require(msg.sender != address(0), "Address zero detected.");
        require(stakers[_address].length > 0, "User not found.");
        return stakers[_address];
    }

    
    function calculateInterest(uint256 principal, uint256 rate, uint256 daysStaked) public pure returns (uint256) {
        // Simple interest formula: Interest = P * r * t
        // Where r = interestRate / 100 and t = daysStaked / DAYS_IN_YEAR
        uint256 timeInYears = daysStaked * 1e18 / DAYS_IN_YEAR; // Converting to wei for precision
        uint256 interest = (principal * rate * timeInYears) / (100 * 1e18); // Calculating interest
        return principal + interest;
    }
}