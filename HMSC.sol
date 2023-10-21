// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Hostel {
    address payable tenant;
    address payable landlord;
    uint256 num_of_rooms = 0;
    uint256 num_of_agreement = 0;
    uint256 num_of_rent = 0;

    struct Room {
        uint256 room_number;
        uint256 agreement_id;
        string room_name;
        string room_address;
        uint256 roomRent_per_month;
        uint256 security_deposite;
        uint256 timestamp;
        bool vacant;
        address payable landlord;
        address payable current_tenant;
    }

    mapping(uint256 => Room) public room_by_number;

    struct RoomAgreement {
        uint256 roomid;
        uint256 agreementid;
        string Roomname;
        string RoomAddresss;
        uint256 rent_per_month;
        uint256 securityDeposit;
        uint256 lockInPeriod;
        uint256 timestamp;
        address payable tenantAddress;
        address payable landlordAddress;
    }
    mapping(uint256 => RoomAgreement) public RoomAgreement_by_No;

    struct Rent {
        uint256 rentno;
        uint256 roomid;
        uint256 agreementid;
        string Roomname;
        string RoomAddresss;
        uint256 rent_per_month;
        uint256 timestamp;
        address payable tenantAddress;
        address payable landlordAddress;
    }
    mapping(uint256 => Rent) public Rent_by_No;

    modifier onlyLandlord(uint256 _index) {
        require(
            msg.sender == room_by_number[_index].landlord,
            "Only landlord can access this"
        );
        _;
    }
    modifier notLandLord(uint256 _index) {
        require(
            msg.sender != room_by_number[_index].landlord,
            "Only Tenant can access this"
        );
        _;
    }
    modifier OnlyWhileVacant(uint256 _index) {
        require(
            room_by_number[_index].vacant == true,
            "Room is currently Occupied."
        );
        _;
    }
    modifier enoughRent(uint256 _index) {
        require(
            msg.value >= uint256(room_by_number[_index].roomRent_per_month),
            "Not enough Ether in your wallet"
        );
        _;
    }
    modifier enoughAgreementfee(uint256 _index) {
        require(
            msg.value >=
                uint256(
                    uint256(room_by_number[_index].roomRent_per_month) +
                        uint256(room_by_number[_index].security_deposite)
                ),
            "Not enough Ether in your wallet"
        );
        _;
    }
    modifier sameTenant(uint256 _index) {
        require(
            msg.sender == room_by_number[_index].current_tenant,
            "No previous agreement found with you & landlord"
        );
        _;
    }
    modifier AgreementTimesLeft(uint256 _index) {
        uint256 _AgreementNo = room_by_number[_index].agreement_id;
        uint256 time = RoomAgreement_by_No[_AgreementNo].timestamp +
            RoomAgreement_by_No[_AgreementNo].lockInPeriod;
        require(block.timestamp < time, "Agreement already Ended");
        _;
    }
    modifier AgreementTimesUp(uint256 _index) {
        uint256 _AgreementNo = room_by_number[_index].agreement_id;
        uint256 time = RoomAgreement_by_No[_AgreementNo].timestamp +
            RoomAgreement_by_No[_AgreementNo].lockInPeriod;
        require(block.timestamp > time, "Time is left for contract to end");
        _;
    }
    modifier RentTimesUp(uint256 _index) {
        uint256 time = room_by_number[_index].timestamp + 30 days;
        require(block.timestamp >= time, "Time left to pay Rent");
        _;
    }
    function addRoom(string memory _roomname, string memory _roomaddress, uint _rentcost, uint  _securitydeposit) public {
        require(msg.sender != address(0));
        num_of_rooms ++;
        bool _vacancy = true;
        room_by_number[num_of_rooms] = Room(num_of_rooms,0,_roomname,_roomaddress, _rentcost,_securitydeposit,0,_vacancy, payable (msg.sender), payable (address(0))); 
        
    }

    function signAgreement(uint256 _index)
        public
        payable
        notLandLord(_index)
        enoughAgreementfee(_index)
        OnlyWhileVacant(_index)
    {
        require(msg.sender != address(0));
        address payable _landlord = room_by_number[_index].landlord;
        uint256 totalfee = room_by_number[_index].roomRent_per_month +
            room_by_number[_index].security_deposite;
        _landlord.transfer(totalfee);
        num_of_agreement++;
        room_by_number[_index].current_tenant = payable(msg.sender);
        room_by_number[_index].vacant = false;
        room_by_number[_index].timestamp = block.timestamp;
        room_by_number[_index].agreement_id = num_of_agreement;
        RoomAgreement_by_No[num_of_agreement] = RoomAgreement(
            _index,
            num_of_agreement,
            room_by_number[_index].room_name,
            room_by_number[_index].room_address,
            room_by_number[_index].roomRent_per_month,
            room_by_number[_index].security_deposite,
            365 days,
            block.timestamp,
            payable(msg.sender),
            _landlord
        );
        num_of_rent++;
        Rent_by_No[num_of_rent] = Rent(
            num_of_rent,
            _index,
            num_of_agreement,
            room_by_number[_index].room_name,
            room_by_number[_index].room_address,
            room_by_number[_index].roomRent_per_month,
            block.timestamp,
            payable (msg.sender),
            _landlord
        );
    }

    function payRent(uint256 _index)
        public
        payable
        sameTenant(_index)
        RentTimesUp(_index)
        enoughRent(_index)
    {
        require(msg.sender != address(0));
        address payable _landlord = room_by_number[_index].landlord;
        uint256 _rent = room_by_number[_index].roomRent_per_month;
        _landlord.transfer(_rent);
        room_by_number[_index].current_tenant = payable (msg.sender);
        room_by_number[_index].vacant = false;
        num_of_rent++;
        Rent_by_No[num_of_rent] = Rent(
            num_of_rent,
            _index,
            room_by_number[_index].agreement_id,
            room_by_number[_index].room_name,
            room_by_number[_index].room_address,
            _rent,
            block.timestamp,
            payable (msg.sender),
            room_by_number[_index].landlord
        );
    }

    function agreementCompleted(uint256 _index)
        public
        payable
        onlyLandlord(_index)
        AgreementTimesUp(_index)
    {
        require(msg.sender != address(0));
        require(
            room_by_number[_index].vacant == false,
            "Room is currently Occupied."
        );
        room_by_number[_index].vacant = true;
        address payable _Tenant = room_by_number[_index].current_tenant;
        uint256 _securitydeposit = room_by_number[_index].security_deposite;
        _Tenant.transfer(_securitydeposit);
    }
      function agreementTerminated(uint _index) public onlyLandlord(_index) AgreementTimesLeft(_index){
        require(msg.sender != address(0));
        room_by_number[_index].vacant = true;
    }
}
