// SPDX-License-Identifier: MIT
/**********************************************************************
The IdentityManager is a smart contract responsible for managing user identities and their roles within a system. It serves as an identity registry and access control mechanism. Here's a brief explanation of its main components and functionalities:

The IdentityManager contract provides functionalities for managing user identities, roles, and access control, enabling secure interactions within a system based on user roles.

Main components and functionalities of the IdentityManager contract:

1. Structures:
	Identity			: Represents the attributes of a user identity, such as name, email, phone number, role, and existence status.
	CryptParams			: Holds cryptographic parameters common to all users, such as public key and nonce.

2. Mappings:
	identities			: Maps user addresses to their corresponding Identity struct.
	users				: Stores the addresses of all registered users.

3. Events:
	IdentityRegistered	: Fired when a new user identity is registered.
	IdentityUpdated		: Fired when an existing user identity is updated.
	IdentityDeleted		: Fired when a user identity is deleted.
	RoleUpgraded		: Fired when a user's role is upgraded.
	CryptParamsUpdated	: Fired when cryptographic parameters are updated.

4. Modifiers:
	onlyOwnerOrServiceProvider: Restricts access to certain functions to the contract owner or the service provider contract.
	onlyOwner			: Restricts access to certain functions to the contract owner.
	onlyServiceProvider	: Restricts access to certain functions to the service provider contract.
	identityExists		: Checks if a user identity exists.

5. Functions:
	registerIdentity	: Registers a new user identity with the specified attributes and role.
	updateIdentity		: Updates the attributes of an existing user identity.
	deleteIdentity		: Deletes a user identity.
	rqstDonorMembership	: Allows users with certain roles to upgrade to the "Donor" role.
	setCryptParams		: Sets the common cryptographic parameters for all users.
	getAllUsers			: Returns the addresses of all registered users.
	hasRole				: Checks if a user has a specific role.

**********************************************************************/


pragma solidity ^0.8.0;

contract IdentityManager {
    enum Role { None, Citizen, Beneficiary, FinancialInstitution, Organization, ECI, Donor }

    struct Identity {
        string name;
        string email;
        string phoneNumber;
        Role role;
        bool exists;
    }

    struct CryptParams {
        bytes publicKey;
        uint256 nonce;
    }

    mapping(address => Identity) private identities;
    CryptParams public cryptParams;
    address[] private users;
    address public owner;
    address public EBserviceProviderContract;

    event IdentityRegistered(address indexed user, string name, string email, string phoneNumber, Role role);
    event IdentityUpdated(address indexed user, string name, string email, string phoneNumber, Role role);
    event IdentityDeleted(address indexed user);
    event RoleUpgraded(address indexed user, Role newRole);
    event CryptParamsUpdated(bytes publicKey, uint256 nonce);

    modifier onlyOwnerOrServiceProvider() {
        require(msg.sender == owner || msg.sender == EBserviceProviderContract, "Unauthorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyServiceProvider() {
        require(msg.sender == EBserviceProviderContract, "Only the service provider contract can perform this action");
        _;
    }

    modifier identityExists(address user) {
        require(identities[user].exists, "Identity does not exist");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setEBServiceProviderContract(address _EBserviceProviderContract) public onlyOwner {
        EBserviceProviderContract = _EBserviceProviderContract;
    }

    function registerIdentity(address user, string memory name, Role role, string memory kyc) external onlyOwner {
        require(!identities[user].exists, "User identity already exists");

        // Perform KYC verification here
        bool isVerified = performKYCVerification(kyc);

        require(isVerified, "KYC verification failed");

        // If KYC is verified, register the user
        identities[user] = Identity(name, role, true);
        users.push(user);
        emit IdentityRegistered(user, name, role);
    }

    function performKYCVerification(string memory kycData) private onlyFinancialInstitution view returns (bool) {
        // Dummy implementation of KYC verification
        // You should implement your actual KYC verification logic here
        return true;
	}
	
    function updateIdentity(address user, string memory name, string memory email, string memory phoneNumber) public onlyOwner identityExists(user) {
        Identity storage identity = identities[user];
        identity.name = name;
        identity.email = email;
        identity.phoneNumber = phoneNumber;

        emit IdentityUpdated(user, name, email, phoneNumber, identity.role);
    }

    function deleteIdentity(address user) public onlyOwner identityExists(user) {
        delete identities[user];
        // You may want to remove the user from the 'users' array here
        emit IdentityDeleted(user);
    }

    function rqstDonorMembership() public onlyOwner {
        Identity storage identity = identities[msg.sender];
        require(identity.role == Role.Citizen || identity.role == Role.Organization, "Role upgrade not allowed for this user");

        identity.role = Role.Donor;

        emit RoleUpgraded(msg.sender, Role.Donor);
    }

    function setCryptParams(bytes memory publicKey, uint256 nonce) public onlyOwner {
        cryptParams = CryptParams(publicKey, nonce);
        emit CryptParamsUpdated(publicKey, nonce);
    }

    function getAllUsers() public view onlyOwnerOrServiceProvider returns (address[] memory) {
        return users;
    }

    function hasRole(address user, Role role) public view onlyServiceProvider identityExists(user) returns (bool) {
        return identities[user].role == role;
    }
}
