pragma solidity ^0.4.24;

import "./InBlock_Data.sol";

contract InBlock_F is InBlock_Data{

//*************************************************** GETTER BLOCK FUNCTIONS ****************************************************************************

function getItem(int id) public view returns (bytes16 ip, address o, uint8 mask,uint _date, bytes a, bytes b, bytes c, bytes d){
		
		ip = blocks[id].ip_address;
        o = blocks[id].o_addr;
		mask= blocks[id].mask;
		_date= blocks[id].date;
		a=blocks[id].info.uri;
		b=blocks[id].info.hash;
		c=blocks[id].info.hashFunction;
		d=blocks[id].Roa;
		return(ip,o,mask,_date,a,b,c,d);

}

function getAddressID(int id) public view returns (bytes16 ip){
		
		ip = blocks[id].ip_address;
        return(ip);

}

	
function countBlockAddress(address a, int start, int stop)view internal returns(uint){
uint count=0;
for(int i=start; i<stop+1; i++){
		if(blocks[i].o_addr==a && !isAllocatedPrefixExpired(i)){
		count=count+1;
		}
		}
	return count;

}

function getIDsBlocksAddress(address a,int start, int stop)view public returns(uint[]result){

	uint count=countBlockAddress(a,start,stop);
	result = new uint[] (count);
	uint counter=0;
	
	for(int i=start;i<stop+1;i++){
		if(blocks[i].o_addr==a && !isAllocatedPrefixExpired(i)){
		result[counter]=uint(i);
		counter=counter+1;
		}
	}
	return result; 

}



//******************************************************* FIXED SIZE BLOCK REQUEST FUNCTIONS *******************************************************


//PrefixRequest With sparse allocation for /32	 NB there is a fixed limit of /32 available blocks.
function prefixRequest() payable public returns(bool){
		
	require((prefixPrice - 32270100000000000)<=msg.value|| msg.value<=(prefixPrice + 32270100000000000) , "Price error");
	
	bool ok=false;
	while(!ok){
		
		if(ID_Index==int(max_allocable_blocks)){
			require(ID_expired!=0);
			int idapp=expired_array_index[ID_expired-1].ind;
			bytes16 app2=blocks[idapp].ip_address;
			setBlockExpired(app2);
			delete_expired();
			ok=true;
			return ok;
		}else{
			
				bytes16 app=sparse(seed);
				int appID=int(reverseSparse(app));
			if(blocks[appID].ip_address==""){
				setBlock(app,allocation_prefix_mask);
				seed=seed+1;
				owner.transfer(msg.value);
				ok=true;
				return ok;
			}
			else {
				seed=seed+1;
			
			}
		}
	}
	revert();
}


 
//function to perform a sequent allocation if an user already has a block and want the contiguos one 
function sequentialAllocationPrefixRequest(bytes16 ip) notStopped() payable public returns (bool){
	
	require(ID_Index<int(max_allocable_blocks));
	require((prefixPrice - 32270100000000000)<=msg.value || msg.value<=(prefixPrice + 32270100000000000) , "Price error");
	int id= int(reverseSparse(ip));
	require(isPrefixInUse(id));
	require(msg.sender==blocks[id].o_addr, "You are not Authorized");
		
		if(!getBit(ip,128-allocation_prefix_mask)){
				ip=setBit(ip,128-allocation_prefix_mask);
		}else{	
				ip=clearBit(ip,128-allocation_prefix_mask);
				uint8 i=1;
				while(i<allocation_prefix_mask-base_prefix_mask){
					
						if(getBit(ip,128-(allocation_prefix_mask-i))){
								ip=clearBit(ip,128-(allocation_prefix_mask-i));
								i++;
						}else{
								ip=setBit(ip,128-(allocation_prefix_mask-i));
								i=allocation_prefix_mask-base_prefix_mask;
							}
						}
			  }
			  
		
		int id1= int(reverseSparse(ip));
		require(blocks[id1].ip_address=="");
		
			setBlock(ip,allocation_prefix_mask);
			owner.transfer(msg.value);
			return true;
		
			revert();
}

//******************************************************* BLOCK RENEWAL FUNCTION *******************************************************

/*
function prefixRenew(bytes16 ip) notStopped() payable public returns (bool,uint){
	
	require(msg.value==prefixPrice, "Price Error.");
	
	int id=int(reverseSparse(ip));
	require(isPrefixInUse(id));
	require(msg.sender==blocks[id].o_addr, "You are not the owner of the block");
	uint app1= (blocks[id].date+365* 1 days)-now;
	blocks[id].date=now+app1;	
	owner.transfer(msg.value);
	return(true,blocks[id].date);
}*/

function prefixRenewID(int id) notStopped() payable public returns (bool,uint){
	
	require(msg.value==prefixPrice, "Price Error.");
	require(isPrefixInUse(id));
	require(msg.sender==blocks[id].o_addr, "You are not the owner of the block");
	uint app1= (blocks[id].date+365* 1 days)-now;
	blocks[id].date=now+app1;	
	owner.transfer(msg.value);
	return(true,blocks[id].date);
}

//******************************************************* BLOCK RECOVER FUNCTION *******************************************************

function countBlockExpired(int start, int stop)view internal returns(uint){
uint count=0;
for(int i=start; i<stop; i++){
		if(isAllocatedPrefixExpired(i)){
		count=count+1;
		}
		}
	return count;

}

function getIDsPrefixExpired(int start, int stop)view public returns(uint[]result){

	uint count=countBlockExpired(start,stop);
	result = new uint[] (count);
	uint counter=0;
	
	for(int i=start;i<stop;i++){
		if(isAllocatedPrefixExpired(i)){
		result[counter]=uint(i);
		counter=counter+1;
		}
	}
	return result; 

}


function recoverExpiredBlock(int id)onlyOwner()public {

	require(isAllocatedPrefixExpired(id));
	blocks[id].ip_address="";
	blocks[id].mask=0;
	blocks[id].o_addr=0x00;
	blocks[id].date=0;
	blocks[id].info.uri="";
	blocks[id].info.hashFunction="";
	blocks[id].info.hash="";
	blocks[id].Roa="";

	expired_array_index[ID_expired].ind=id;
	ID_expired=ID_expired+1;

}


function getRecovered()view public returns(uint[]result){

	uint count=uint(ID_expired);
	result = new uint[] (count);
	uint counter=0;
	
	for(int i=0;i<ID_expired;i++){
			result[counter]=uint(expired_array_index[i].ind);
			counter=counter+1;
		}
	
	return result; 

}

function delete_expired()internal{

	delete expired_array_index[ID_expired];
	ID_expired=ID_expired-1;

}

//******************************************************* POLICY FUNCTIONS *******************************************************
function setPolicyURI(bytes16 ip, bytes uri, bytes hashFunction, bytes hash) public {
	
	int id=int(reverseSparse(ip));
	require(isPrefixInUse(id));
	blocks[id].info.uri=uri;
	blocks[id].info.hashFunction=hashFunction;
	blocks[id].info.hash=hash;
			
}

function setPolicyURIiD(int id, bytes uri, bytes hashFunction, bytes hash) public {
	
	require(isPrefixInUse(id));
	blocks[id].info.uri=uri;
	blocks[id].info.hashFunction=hashFunction;
	blocks[id].info.hash=hash;
			
}


function getPolicyURI(bytes16 ip) public returns(bytes, bytes, bytes ) {
	
	int id=int(reverseSparse(ip));
	require(isPrefixInUse(id));
	return(blocks[id].info.uri,blocks[id].info.hashFunction,blocks[id].info.hash);
	
	
			
}

//******************************************************* ASes FUNCTIONS *******************************************************

function getRoA(bytes16 ip)view public returns(bytes){
	
	int id=int(reverseSparse(ip));
	require(isPrefixInUse(id));
	return blocks[id].Roa;
}


function setRoA(bytes16 ip, bytes ASes) public {
					
	int id=int(reverseSparse(ip));
	require(isPrefixInUse(id));
	require(msg.sender==blocks[id].o_addr);
	blocks[id].Roa=ASes;
}


function setRoAID(int id, bytes ASes) public {

	require(isPrefixInUse(id));
	require(msg.sender==blocks[id].o_addr);
	blocks[id].Roa=ASes;
}

//*****************************************************BLOCKS SETTER*************************************************************
	
function setBlock(bytes16 ip,uint8 mask)internal {

int id=int(reverseSparse(ip));
blocks[id].ip_address=ip;
blocks[id].o_addr=msg.sender;
blocks[id].mask=mask;
blocks[id].date=now;
blocks[id].ID_delegated=1;
ID_Index=ID_Index+1;
}


 
function setBlockExpired(bytes16 ip) internal {
	int id=int(reverseSparse(ip));	
	blocks[id].ip_address=ip;
	blocks[id].o_addr=msg.sender;
	blocks[id].mask=allocation_prefix_mask;
	blocks[id].date=now;
	blocks[id].Roa="";
	blocks[id].info.uri="";
	blocks[id].info.hashFunction="";
	blocks[id].info.hash="";
	ID_Index=ID_Index+1;
}


}//END 