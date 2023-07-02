// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OHMYToken is ERC20, Ownable, Pausable {
    using SafeMath for uint256;

    struct VestingSchedule {
        uint256 cliff; // Cliff period in seconds
        uint256 vesting; // Vesting period in seconds
    }

    struct AllocationGroup {
        address[] addresses;
        uint256 totalTokens;
        mapping(address => uint256) claimableTokens;
        VestingSchedule vestingSchedule;
    }

    AllocationGroup[] public allocationGroups;

    uint256 public tgeTimestamp; // TGE (Token Generation Event) timestamp
    bool public tgeCompleted; // Flag to indicate if TGE is completed

    constructor(
    string memory _name,
    string memory _symbol,
    uint256 _tgeTimestamp
) ERC20(_name, _symbol) {
    require(_tgeTimestamp > block.timestamp, "Invalid TGE timestamp");

    tgeTimestamp = _tgeTimestamp;
    tgeCompleted = false;

    // Pre-seed Round
    uint256 preSeedCliff = 8 * 30 days; // 8 months
    uint256 preSeedVesting = 7 * 30 days; // 7 months
    allocationGroups.push();
    setAllocationGroup(0, preSeedCliff, preSeedVesting);

    // Option Pool
    uint256 optionPoolCliff = 9 * 30 days; // 9 months
    uint256 optionPoolVesting = 7 * 30 days; // 7 months
    allocationGroups.push();
    setAllocationGroup(1, optionPoolCliff, optionPoolVesting);

    // Seed Round
    uint256 seedRoundCliff = 10 * 30 days; // 10 months
    uint256 seedRoundVesting = 7 * 30 days; // 7 months
    allocationGroups.push();
    setAllocationGroup(2, seedRoundCliff, seedRoundVesting);

    // Round A
    uint256 roundACliff = 8 * 30 days; // 8 months
    uint256 roundAVesting = 10 * 30 days; // 10 months
    allocationGroups.push();
    setAllocationGroup(3, roundACliff, roundAVesting);

    // Round B
    uint256 roundBCliff = 12 * 30 days; // 12 months
    uint256 roundBVesting = 12 * 30 days; // 12 months
    allocationGroups.push();
    setAllocationGroup(4, roundBCliff, roundBVesting);

    // Advisors
    uint256 advisorsCliff = 12 * 30 days; // 12 months
    uint256 advisorsVesting = 7 * 30 days; // 7 months
    allocationGroups.push();
    setAllocationGroup(5, advisorsCliff, advisorsVesting);

    // Team
    uint256 teamCliff = 12 * 30 days; // 12 months
    uint256 teamVesting = 24 * 30 days; // 24 months
    allocationGroups.push();
    setAllocationGroup(6, teamCliff, teamVesting);

    // Partnership
    uint256 partnershipCliff = 12 * 30 days; // 12 months
    uint256 partnershipVesting = 7 * 30 days; // 7 months
    allocationGroups.push();
    setAllocationGroup(7, partnershipCliff, partnershipVesting);

    // Airdrop
    uint256 airdropCliff = 8 * 30 days; // 8 months
    uint256 airdropVesting = 4 * 30 days; // 4 months
    allocationGroups.push();
    setAllocationGroup(8, airdropCliff, airdropVesting);

    // Play to Earn
    uint256 playToEarnCliff = 8 * 30 days; // 8 months
    uint256 playToEarnVesting = 4 * 30 days; // 4 months
    allocationGroups.push();
    setAllocationGroup(9, playToEarnCliff, playToEarnVesting);

    // Marketing
    uint256 marketingCliff = 8 * 30 days; // 8 months
    uint256 marketingVesting = 20 * 30 days; // 20 months
    allocationGroups.push();
    setAllocationGroup(10, marketingCliff, marketingVesting);

    // Liquidity
    allocationGroups.push();
    setAllocationGroup(11, 0, 0);
}

    function setAllocationGroup(
        uint256 _groupId,
        uint256 _cliff,
        uint256 _vestingPeriod
    ) internal {
        allocationGroups[_groupId].vestingSchedule = VestingSchedule(_cliff, _vestingPeriod);
    }

    function addInvestor(address _investor, uint256 _tokens, uint256 _groupId) external onlyOwner {
        require(!tgeCompleted, "TGE completed, no new investors can be added");
        require(_groupId < allocationGroups.length, "Invalid group ID");

        AllocationGroup storage group = allocationGroups[_groupId];
        group.addresses.push(_investor);
        group.totalTokens = group.totalTokens.add(_tokens);
        group.claimableTokens[_investor] = group.claimableTokens[_investor].add(_tokens);
        _mint(address(this), _tokens);
    }

    function completeTge() external onlyOwner {
        require(!tgeCompleted, "TGE already completed");
        tgeCompleted = true;
    }

    function claimTokens() external whenNotPaused {
        require(tgeCompleted, "TGE not completed yet");
        require(tgeTimestamp > 0, "TGE timestamp not set");

        uint256 allocationGroupsLength = allocationGroups.length;
        for (uint256 i = 0; i < allocationGroupsLength; i++) {
            AllocationGroup storage group = allocationGroups[i];
            address[] storage addresses = group.addresses;
            uint256 addressesLength = addresses.length;

            for (uint256 j = 0; j < addressesLength; j++) {
                address recipient = addresses[j];
                uint256 claimableAmount = group.claimableTokens[recipient];
                uint256 vestedAmount = calculateVestedAmount(group.vestingSchedule, claimableAmount);

                if (vestedAmount > 0) {
                    group.claimableTokens[recipient] = group.claimableTokens[recipient].sub(vestedAmount);
                    _transfer(address(this), recipient, vestedAmount);
                }
            }
        }
    }

    function calculateVestedAmount(VestingSchedule memory _vestingSchedule, uint256 _claimableAmount)
        private
        view
        returns (uint256)
    {
        uint256 elapsedTime = block.timestamp.sub(tgeTimestamp);

        if (elapsedTime <= _vestingSchedule.cliff) {
            return 0;
        } else if (elapsedTime >= _vestingSchedule.vesting) {
            return _claimableAmount;
        } else {
            return _claimableAmount.mul(elapsedTime.sub(_vestingSchedule.cliff)).div(_vestingSchedule.vesting.sub(_vestingSchedule.cliff));
        }
    }

    // Additional functions based on best practices

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
}