// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20Vestable {
    function setVestingSchedule(address beneficiary, uint256 cliffDuration, uint256 vestingDuration, uint256 totalAmount) external;
    function releaseVestedTokens() external;
    function revokeVesting() external;
    function getVestedBalance(address beneficiary) external view returns (uint256);
}

contract OHMYToken is ERC20, Ownable, IERC20Vestable {
    struct VestingSchedule {
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTime;
    }

    mapping(address => VestingSchedule) public vestingSchedules;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function setVestingSchedule(address beneficiary, uint256 cliffDuration, uint256 vestingDuration, uint256 totalAmount) external override onlyOwner {
        require(beneficiary != address(0), "Invalid beneficiary address");
        require(cliffDuration > 0, "Cliff duration must be greater than zero");
        require(vestingDuration > 0, "Vesting duration must be greater than zero");
        require(totalAmount > 0, "Total amount must be greater than zero");

        uint256 startTime = block.timestamp;
        VestingSchedule memory schedule = VestingSchedule(cliffDuration, vestingDuration, totalAmount, 0, startTime);
        vestingSchedules[beneficiary] = schedule;

        _mint(address(this), totalAmount);
        _transfer(address(this), beneficiary, totalAmount);
    }

    function releaseVestedTokens() external override {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(schedule.startTime > 0, "No vesting schedule found");
        uint256 cliffEnd = schedule.startTime + schedule.cliffDuration;
        require(block.timestamp >= cliffEnd, "Vesting cliff period has not ended");

        uint256 vestedAmount = calculateVestedAmount(schedule);
        require(vestedAmount > 0, "No tokens available for release");

        schedule.releasedAmount += vestedAmount;
        _transfer(address(this), msg.sender, vestedAmount);
    }

    function revokeVesting() external override onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(schedule.startTime > 0, "No vesting schedule found");

        uint256 unreleasedAmount = schedule.totalAmount - schedule.releasedAmount;
        require(unreleasedAmount > 0, "No tokens to revoke");

        delete vestingSchedules[msg.sender];
        _transfer(address(this), msg.sender, unreleasedAmount);
    }

    function getVestedBalance(address beneficiary) external view override returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.startTime > 0, "No vesting schedule found");

        return calculateVestedAmount(schedule);
    }

    function calculateVestedAmount(VestingSchedule memory schedule) internal view returns (uint256) {
        uint256 elapsedTime = block.timestamp - (schedule.startTime + schedule.cliffDuration);
        uint256 vestingPeriod = schedule.vestingDuration - schedule.cliffDuration;

        if (elapsedTime < vestingPeriod) {
            return schedule.totalAmount * elapsedTime / vestingPeriod - schedule.releasedAmount;
        } else {
            return schedule.totalAmount - schedule.releasedAmount;
        }
    }
}