// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title CommunityCredentials
/// @notice A small on-chain credential system for informal community work.
contract CommunityCredentials {
    struct Credential {
        string title;
        uint256 level;
        uint256 issuedAt;
    }

    address public immutable admin;
    uint256 public constant BASIC_LEVEL = 1;
    uint256 public constant INTERMEDIATE_LEVEL = 2;
    uint256 public constant ADVANCED_LEVEL = 3;
    uint256 public constant ACCESS_THRESHOLD = 25;

    mapping(address => Credential[]) private credentialsByMember;
    mapping(address => mapping(bytes32 => bool)) private hasCredentialTitle;

    event CredentialIssued(
        address indexed member,
        string title,
        uint256 level,
        uint256 issuedAt
    );

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can issue credentials");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /// @notice Issues one credential to a member wallet.
    /// @dev The deployer is the only admin, so credentials come from the community account instead of self-claims.
    /// Duplicate rule: the same title cannot be issued twice to the same wallet. I reject duplicates because
    /// the same achievement should not inflate a member's score; new work should be recorded with a new title.
    function issueCredential(
        address member,
        string calldata title,
        uint256 level
    ) external onlyAdmin {
        require(member != address(0), "Member address cannot be zero");
        require(bytes(title).length > 0, "Title cannot be empty");
        require(
            level >= BASIC_LEVEL && level <= ADVANCED_LEVEL,
            "Level must be 1, 2, or 3"
        );

        bytes32 titleKey = keccak256(bytes(title));
        require(
            !hasCredentialTitle[member][titleKey],
            "Credential title already issued"
        );

        credentialsByMember[member].push(
            Credential({title: title, level: level, issuedAt: block.timestamp})
        );
        hasCredentialTitle[member][titleKey] = true;

        emit CredentialIssued(member, title, level, block.timestamp);
    }

    /// @notice Returns every credential attached to a wallet.
    /// @dev Anyone can read this list because the point is public proof that a community vouched for the address.
    function getCredentials(address member)
        external
        view
        returns (Credential[] memory)
    {
        return credentialsByMember[member];
    }

    /// @notice Returns the number of credentials held by a wallet.
    function credentialCount(address member) external view returns (uint256) {
        return credentialsByMember[member].length;
    }

    /// @notice Computes a simple trust score from a member's credentials.
    /// @dev Formula: each credential adds 5 base points, plus level^2 * 5 points.
    /// Basic credentials are worth 10 total, intermediate 25, and advanced 50.
    /// The base points reward steady participation over time, while the squared level bonus makes higher-skill
    /// contributions count more without letting a single low-level badge look the same as advanced work.
    function trustScore(address member) public view returns (uint256 score) {
        Credential[] storage memberCredentials = credentialsByMember[member];

        for (uint256 i = 0; i < memberCredentials.length; i++) {
            uint256 level = memberCredentials[i].level;
            score += 5 + (level * level * 5);
        }
    }

    /// @notice Returns true only when the caller has enough on-chain trust.
    /// @dev The revert reason is clear so Remix shows exactly why a low-score wallet was blocked.
    function accessGranted() external view returns (bool) {
        require(
            trustScore(msg.sender) >= ACCESS_THRESHOLD,
            "Trust score below access threshold"
        );

        return true;
    }

    /// @dev Credentials are non-transferable because this contract has no transfer, approval, or owner-changing
    /// function. Records are stored directly under the recipient address in credentialsByMember, so moving a
    /// credential would require admin-only storage mutation that does not exist. This keeps the proof tied to the
    /// wallet that earned it and stops one person from selling or handing reputation to someone else.
}
