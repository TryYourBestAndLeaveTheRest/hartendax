// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;


import {KRNL, KrnlPayload, KernelParameter, KernelResponse} from "./KRNL.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Sample is KRNL, ERC1155 {
    // Token Authority public key as a constructor
    constructor(
        address _tokenAuthorityPublicKey
    ) KRNL(_tokenAuthorityPublicKey) ERC1155("") {}
    uint256 public currentEventId;

    struct Event {
        string uri;
        address creator;
        mapping(address => bool) claimed;
        address[] attendees;
    }

    mapping(uint256 => Event) private events;

    event EventCreated(
        uint256 indexed eventId,
        address indexed creator,
        string uri
    );
    event BadgeClaimed(uint256 indexed eventId, address indexed user);

    function createEvent(
        KrnlPayload memory krnlPayload,
        string memory uri
    ) external onlyAuthorized(krnlPayload, abi.encode(uri)) {
        // Decode response from kernel
        KernelResponse[] memory kernelResponses = abi.decode(
            krnlPayload.kernelResponses,
            (KernelResponse[])
        );
        bool isValid;
        for (uint i; i < kernelResponses.length; i++) {
            if (kernelResponses[i].kernelId == 337) {
                isValid = abi.decode(kernelResponses[i].result, (bool));
            }
        }
        // if (!isValid) {
        //     revert("Invalid kernel response");
        // }

        require(bytes(uri).length > 0, "URI is required");
        currentEventId++;
        Event storage newEvent = events[currentEventId];
        newEvent.uri = uri;
        newEvent.creator = msg.sender;

        emit EventCreated(currentEventId, msg.sender, uri);
    }

    function claimBadge(
        KrnlPayload memory krnlPayload,
        uint256 eventId
    ) external onlyAuthorized(krnlPayload, abi.encode(eventId)) {
        KernelResponse[] memory kernelResponses = abi.decode(
            krnlPayload.kernelResponses,
            (KernelResponse[])
        );
        bool isValid;
        for (uint i; i < kernelResponses.length; i++) {
            if (kernelResponses[i].kernelId == 337) {
                isValid = abi.decode(kernelResponses[i].result, (bool));
            }
        }
        // if (!isValid) {
        //     revert("Invalid kernel response");
        // }
        Event storage e = events[eventId];
        require(e.creator != address(0), "Event does not exist");
        require(!e.claimed[msg.sender], "Already claimed");
        e.claimed[msg.sender] = true;
        e.attendees.push(msg.sender);
        _mint(msg.sender, eventId, 1, "");

        emit BadgeClaimed(eventId, msg.sender);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return events[tokenId].uri;
    }

    function hasClaimed(
        uint256 eventId,
        address user
    ) external view returns (bool) {
        return events[eventId].claimed[user];
    }

    function getAttendees(
        uint256 eventId
    ) external view returns (address[] memory) {
        require(
            msg.sender == events[eventId].creator,
            "Only creator can view attendees"
        );
        return events[eventId].attendees;
    }
}
