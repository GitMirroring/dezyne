// Dezyne --- Dezyne command line tools
// Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
// Copyright © 2015, 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// This file is part of Dezyne.
//
// Dezyne is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Dezyne is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

/*
 * Generic map implementation.
 */

#include <dzn/config.h>
#include <dzn/map.h>
#include <dzn/mem.h>



#if DZN_LOCATOR_SERVICES
#include <assert.h>
#include <limits.h>
#include <string.h>


#define INITIAL_SIZE (256)
#define MAX_CHAIN_LENGTH (8)

/*
 * Return an empty map, or NULL on failure.
 */
void
map_init (map* self) {
    self->data = (map_element*) dzn_calloc((size_t)INITIAL_SIZE, sizeof(map_element));
    assert (self->data);
    self->table_size = (size_t)INITIAL_SIZE;
    self->size = 0u;
}
/* The implementation here was originally done by Gary S. Brown.  I have
   borrowed the tables directly, and made some minor changes to the
   crc32-function (including changing the interface). //ylo */

  /* ============================================================= */
  /*  COPYRIGHT (C) 1986 Gary S. Brown.  You may use this program, or       */
  /*  code or tables extracted from it, as desired without restriction.     */
  /*                                                                        */
  /*  First, the polynomial itself and its table of feedback terms.  The    */
  /*  polynomial is                                                         */
  /*  X^32+X^26+X^23+X^22+X^16+X^12+X^11+X^10+X^8+X^7+X^5+X^4+X^2+X^1+X^0   */
  /*                                                                        */
  /*  Note that we take it "backwards" and put the highest-order term in    */
  /*  the lowest-order bit.  The X^32 term is "implied"; the LSB is the     */
  /*  X^31 term, etc.  The X^0 term (usually shown as "+1") results in      */
  /*  the MSB being 1.                                                      */
  /*                                                                        */
  /*  Note that the usual hardware shift register implementation, which     */
  /*  is what we're using (we're merely optimizing it by doing eight-bit    */
  /*  chunks at a time) shifts bits into the lowest-order term.  In our     */
  /*  implementation, that means shifting towards the right.  Why do we     */
  /*  do it this way?  Because the calculated CRC must be transmitted in    */
  /*  order from highest-order term to lowest-order term.  UARTs transmit   */
  /*  characters in order from LSB to MSB.  By storing the CRC this way,    */
  /*  we hand it to the UART in the order low-byte to high-byte; the UART   */
  /*  sends each low-bit to hight-bit; and the result is transmission bit   */
  /*  by bit from highest- to lowest-order term without requiring any bit   */
  /*  shuffling on our part.  Reception works similarly.                    */
  /*                                                                        */
  /*  The feedback terms table consists of 256, 32-bit entries.  Notes:     */
  /*                                                                        */
  /*      The table can be generated at runtime if desired; code to do so   */
  /*      is shown later.  It might not be obvious, but the feedback        */
  /*      terms simply represent the results of eight shift/xor opera-      */
  /*      tions for all combinations of data and CRC register values.       */
  /*                                                                        */
  /*      The values must be right-shifted by eight bits by the "updcrc"    */
  /*      logic; the shift must be unsigned (bring in zeroes).  On some     */
  /*      hardware you could probably optimize the shift in assembler by    */
  /*      using byte-swap instructions.                                     */
  /*      polynomial $edb88320                                              */
  /*                                                                        */
  /*  --------------------------------------------------------------------  */

static uint32_t crc32_tab[] = {
    0x00000000LU, 0x77073096LU, 0xee0e612cLU, 0x990951baLU, 0x076dc419LU,
    0x706af48fLU, 0xe963a535LU, 0x9e6495a3LU, 0x0edb8832LU, 0x79dcb8a4LU,
    0xe0d5e91eLU, 0x97d2d988LU, 0x09b64c2bLU, 0x7eb17cbdLU, 0xe7b82d07LU,
    0x90bf1d91LU, 0x1db71064LU, 0x6ab020f2LU, 0xf3b97148LU, 0x84be41deLU,
    0x1adad47dLU, 0x6ddde4ebLU, 0xf4d4b551LU, 0x83d385c7LU, 0x136c9856LU,
    0x646ba8c0LU, 0xfd62f97aLU, 0x8a65c9ecLU, 0x14015c4fLU, 0x63066cd9LU,
    0xfa0f3d63LU, 0x8d080df5LU, 0x3b6e20c8LU, 0x4c69105eLU, 0xd56041e4LU,
    0xa2677172LU, 0x3c03e4d1LU, 0x4b04d447LU, 0xd20d85fdLU, 0xa50ab56bLU,
    0x35b5a8faLU, 0x42b2986cLU, 0xdbbbc9d6LU, 0xacbcf940LU, 0x32d86ce3LU,
    0x45df5c75LU, 0xdcd60dcfLU, 0xabd13d59LU, 0x26d930acLU, 0x51de003aLU,
    0xc8d75180LU, 0xbfd06116LU, 0x21b4f4b5LU, 0x56b3c423LU, 0xcfba9599LU,
    0xb8bda50fLU, 0x2802b89eLU, 0x5f058808LU, 0xc60cd9b2LU, 0xb10be924LU,
    0x2f6f7c87LU, 0x58684c11LU, 0xc1611dabLU, 0xb6662d3dLU, 0x76dc4190LU,
    0x01db7106LU, 0x98d220bcLU, 0xefd5102aLU, 0x71b18589LU, 0x06b6b51fLU,
    0x9fbfe4a5LU, 0xe8b8d433LU, 0x7807c9a2LU, 0x0f00f934LU, 0x9609a88eLU,
    0xe10e9818LU, 0x7f6a0dbbLU, 0x086d3d2dLU, 0x91646c97LU, 0xe6635c01LU,
    0x6b6b51f4LU, 0x1c6c6162LU, 0x856530d8LU, 0xf262004eLU, 0x6c0695edLU,
    0x1b01a57bLU, 0x8208f4c1LU, 0xf50fc457LU, 0x65b0d9c6LU, 0x12b7e950LU,
    0x8bbeb8eaLU, 0xfcb9887cLU, 0x62dd1ddfLU, 0x15da2d49LU, 0x8cd37cf3LU,
    0xfbd44c65LU, 0x4db26158LU, 0x3ab551ceLU, 0xa3bc0074LU, 0xd4bb30e2LU,
    0x4adfa541LU, 0x3dd895d7LU, 0xa4d1c46dLU, 0xd3d6f4fbLU, 0x4369e96aLU,
    0x346ed9fcLU, 0xad678846LU, 0xda60b8d0LU, 0x44042d73LU, 0x33031de5LU,
    0xaa0a4c5fLU, 0xdd0d7cc9LU, 0x5005713cLU, 0x270241aaLU, 0xbe0b1010LU,
    0xc90c2086LU, 0x5768b525LU, 0x206f85b3LU, 0xb966d409LU, 0xce61e49fLU,
    0x5edef90eLU, 0x29d9c998LU, 0xb0d09822LU, 0xc7d7a8b4LU, 0x59b33d17LU,
    0x2eb40d81LU, 0xb7bd5c3bLU, 0xc0ba6cadLU, 0xedb88320LU, 0x9abfb3b6LU,
    0x03b6e20cLU, 0x74b1d29aLU, 0xead54739LU, 0x9dd277afLU, 0x04db2615LU,
    0x73dc1683LU, 0xe3630b12LU, 0x94643b84LU, 0x0d6d6a3eLU, 0x7a6a5aa8LU,
    0xe40ecf0bLU, 0x9309ff9dLU, 0x0a00ae27LU, 0x7d079eb1LU, 0xf00f9344LU,
    0x8708a3d2LU, 0x1e01f268LU, 0x6906c2feLU, 0xf762575dLU, 0x806567cbLU,
    0x196c3671LU, 0x6e6b06e7LU, 0xfed41b76LU, 0x89d32be0LU, 0x10da7a5aLU,
    0x67dd4accLU, 0xf9b9df6fLU, 0x8ebeeff9LU, 0x17b7be43LU, 0x60b08ed5LU,
    0xd6d6a3e8LU, 0xa1d1937eLU, 0x38d8c2c4LU, 0x4fdff252LU, 0xd1bb67f1LU,
    0xa6bc5767LU, 0x3fb506ddLU, 0x48b2364bLU, 0xd80d2bdaLU, 0xaf0a1b4cLU,
    0x36034af6LU, 0x41047a60LU, 0xdf60efc3LU, 0xa867df55LU, 0x316e8eefLU,
    0x4669be79LU, 0xcb61b38cLU, 0xbc66831aLU, 0x256fd2a0LU, 0x5268e236LU,
    0xcc0c7795LU, 0xbb0b4703LU, 0x220216b9LU, 0x5505262fLU, 0xc5ba3bbeLU,
    0xb2bd0b28LU, 0x2bb45a92LU, 0x5cb36a04LU, 0xc2d7ffa7LU, 0xb5d0cf31LU,
    0x2cd99e8bLU, 0x5bdeae1dLU, 0x9b64c2b0LU, 0xec63f226LU, 0x756aa39cLU,
    0x026d930aLU, 0x9c0906a9LU, 0xeb0e363fLU, 0x72076785LU, 0x05005713LU,
    0x95bf4a82LU, 0xe2b87a14LU, 0x7bb12baeLU, 0x0cb61b38LU, 0x92d28e9bLU,
    0xe5d5be0dLU, 0x7cdcefb7LU, 0x0bdbdf21LU, 0x86d3d2d4LU, 0xf1d4e242LU,
    0x68ddb3f8LU, 0x1fda836eLU, 0x81be16cdLU, 0xf6b9265bLU, 0x6fb077e1LU,
    0x18b74777LU, 0x88085ae6LU, 0xff0f6a70LU, 0x66063bcaLU, 0x11010b5cLU,
    0x8f659effLU, 0xf862ae69LU, 0x616bffd3LU, 0x166ccf45LU, 0xa00ae278LU,
    0xd70dd2eeLU, 0x4e048354LU, 0x3903b3c2LU, 0xa7672661LU, 0xd06016f7LU,
    0x4969474dLU, 0x3e6e77dbLU, 0xaed16a4aLU, 0xd9d65adcLU, 0x40df0b66LU,
    0x37d83bf0LU, 0xa9bcae53LU, 0xdebb9ec5LU, 0x47b2cf7fLU, 0x30b5ffe9LU,
    0xbdbdf21cLU, 0xcabac28aLU, 0x53b39330LU, 0x24b4a3a6LU, 0xbad03605LU,
    0xcdd70693LU, 0x54de5729LU, 0x23d967bfLU, 0xb3667a2eLU, 0xc4614ab8LU,
    0x5d681b02LU, 0x2a6f2b94LU, 0xb40bbe37LU, 0xc30c8ea1LU, 0x5a05df1bLU,
    0x2d02ef8dLU
};

/* Return a 32-bit CRC of the contents of the buffer. */

static uint32_t crc32(const char_t *s, const uint32_t len);
static uint32_t crc32(const char_t *s, const uint32_t len)
{
    uint16_t i;
    uint32_t crc32val;

    crc32val = 0u;
    for (i = 0u;  i < len;  i ++)
    {
      crc32val = crc32_tab[(crc32val ^ (uint32_t)s[i]) & 0xffu]^(crc32val >> 8);
    }
    return crc32val;
}

/*
 * Hashing function for a string
 */
uint32_t map_hash_int(const map* self,const char_t* keystring){
    uint32_t key = crc32(keystring, (uint32_t)strlen(keystring));

    /* Robert Jenkins' 32 bit Mix Function */
    key += (key << 12);
    key ^= (key >> 22);
    key += (key << 4);
    key ^= (key >> 9);
    key += (key << 10);
    key ^= (key >> 2);
    key += (key << 7);
    key ^= (key >> 12);

    /* Knuth's Multiplicative Method */
    key = (key >> 3) * 2654435761LU;
    return (uint32_t)key % (uint32_t)self->table_size;
}

/*
 * Return the integer of the location in data
 * to store the point to the item, or MAP_FULL.
 */
int32_t map_hash(const map* self,const char_t* key){
  uint32_t curr;
  uint8_t i;
  bool strcmp_result;
  int32_t map_hash_response = INT_MIN;


	/* If full, return immediately */
  if(self->size >= (self->table_size/2u)){
    map_hash_response = MAP_FULL;
  }
  else
    {
      /* Find the best index */
      curr = map_hash_int(self, key);
      /* Linear probing */
      for(i = 0u; i<(uint8_t) MAX_CHAIN_LENGTH; i++){


        if((self->data[curr].in_use == false)){
            map_hash_response = (int32_t) curr;
        }
        else
        {
          strcmp_result = (strcmp(self->data[curr].key,key)==0) ? true : false;
          if ((self->data[curr].in_use == true) && strcmp_result){
            map_hash_response = (int32_t) curr;
          }
        }
        if (map_hash_response == (int32_t) curr) { break;}

        if (i == ((uint8_t)MAX_CHAIN_LENGTH-1u)){
          map_hash_response = MAP_FULL;
        }
        else
        {
          curr = (curr + 1u) % (uint32_t)self->table_size;
        }
      }
    }
  return  map_hash_response;
}

/*
 * Doubles the size of the map, and rehashes all the elements
 */



int32_t map_rehash(map* self){
    uint16_t i;
    size_t old_size;
    map_element* curr;
    int32_t map_rehash_response = (int32_t)INT_MIN;

    /* Setup the new elements */
    map_element* temp = (map_element *)dzn_calloc(2u * (size_t)self->table_size, sizeof(map_element));
    if(temp==0){
      map_rehash_response = MAP_OMEM;
    }
    else
    {
	/* Update the array */
	curr = self->data;
	self->data = temp;

	/* Update the size */
	old_size = self->table_size;
	self->table_size = 2u * self->table_size;
	self->size = 0u;

	/* Rehash the elements */
	for(i = 0u; i < old_size; i++){
	  int32_t status;
	  if (curr[i].in_use != false){
      status = map_put(self, curr[i].key, curr[i].data);
      if (status != MAP_OK){
		    map_rehash_response = status;
		    break;
      }
	  }
	}

	if (map_rehash_response == INT_MIN)
	{
	    dzn_free(curr);
	    map_rehash_response = MAP_OK;
	}

    }
    return map_rehash_response;

}

/*
 * Add a pointer to the map with some key
 */
int32_t map_put(map* self, char_t* key, void* value){
  int32_t index;
  int32_t map_put_response = INT_MIN;
  /* Find a place to put our value */
  index = map_hash(self, key);
  while(index == MAP_FULL){
    if (map_rehash(self) == MAP_OMEM) {
	    map_put_response = MAP_OMEM;
	    break;
    }
    index = map_hash(self, key);
  }
  if (map_put_response == INT_MIN)
    {
	    /* Set the data */
    	self->data[index].data = value;
	    self->data[index].key = key;
	    self->data[index].in_use = true;
	    self->size++;
	    map_put_response = MAP_OK;
    }
  return map_put_response;
}

/*
 * Get your pointer out of the map with a key
 */
int32_t map_get(const map* self, const char_t* key, void* *arg){
  uint32_t curr;
  uint8_t i;
  int32_t map_get_response;

  /* Find data location */
  curr = map_hash_int(self, key);

  /* Linear probing, if necessary */
  for(i = 0u; i<(uint8_t)MAX_CHAIN_LENGTH; i++){
    bool in_use = self->data[curr].in_use;
    if (in_use == true){
	    if (strcmp(self->data[curr].key,key)==0){
        *arg = (self->data[curr].data);
        map_get_response = MAP_OK;
        break;
	    }
    }
    curr = (curr + 1u) % (uint32_t) self->table_size;
    if ( i == ((uint8_t)MAX_CHAIN_LENGTH - 1u))
      {
        map_get_response = MAP_MISSING;
      }

  }
  if (map_get_response == MAP_MISSING)
    {
      *arg = NULL;
    }
  /* Not found */
  return map_get_response;
}

/*
 * Iterate the function formal over each element in the map.  The
 * additional void* argument is passed to the function as its first
 * argument and the map element is the second.
 */
int32_t map_iterate(map* self, map_f f, void* item) {
  uint16_t i;
  int32_t map_iterate_response;
  /* On empty map, return immediately */
  if (map_length(self) <= 0u){
    map_iterate_response = MAP_MISSING;
  }
  else
  {
  /* Linear probing */
    for(i = 0u; i<self->table_size; i++){
      if(self->data[i].in_use != false) {
        void* data = &self->data[i];
        int32_t status = f(data, item);
        if (status != MAP_OK) {
          map_iterate_response = status;
          break;
        }
	    }
	    /* loop reached the end thus map is k*/
      if (i == (self->table_size - 1u))
        {
          map_iterate_response = MAP_OK;
        }
    }
  }
    return map_iterate_response;
}

/*
 * Remove an element with that key from the map
 */
int32_t map_remove(map* self,const char_t* key){
  uint8_t i;
  uint32_t curr;
  int32_t map_remove_return_val;

  /* Find key */
  curr = map_hash_int(self, key);

  /* Linear probing, if necessary */
  for(i = 0u; i<(uint8_t)MAX_CHAIN_LENGTH; i++){
    bool in_use = self->data[curr].in_use;
    if (in_use == true){
	    if (strcmp(self->data[curr].key,key)==0){
        /* Blank out the fields */
        self->data[curr].in_use = false;
        self->data[curr].data = NULL;
        self->data[curr].key = NULL;

        /* Reduce the size */
        self->size--;
        map_remove_return_val = MAP_OK;
        break;
	    }
    }
    curr = (curr + 1u) % (uint32_t) self->table_size;
    if (i == ((uint8_t)MAX_CHAIN_LENGTH-1u))
      {
        /* Data not found */
        map_remove_return_val = MAP_MISSING;
      }
  }

  return map_remove_return_val;
}

/* Deallocate the map */
void map_free(map* self){
    dzn_free(self->data);
    dzn_free(self);
}

/* Return the length of the map */
uint8_t map_length(const map* self){
  return (self != NULL) ? (uint8_t)self->size : 0u;
}

#ifdef MAP_TEST
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>

#include <dzn/map.h>

#define KEY_MAX_LENGTH (256)
#define KEY_PREFIX ("somekey")
#define KEY_COUNT (1024*1024)

typedef struct data_struct_t data_struct;
struct data_struct_t{
    char key_string[KEY_MAX_LENGTH];
    int number;
};

int main(char* argv, int argc)
{
    int index;
    int error;
    map mymap;
    char key_string[KEY_MAX_LENGTH];
    data_struct* value;

    mymap = map_new();

    /* First, populate the hash map with ascending values */
    for (index=0; index<KEY_COUNT; index+=1)
    {
        /* Store the key string along side the numerical value so we can free it later */
        value = malloc(sizeof(data_struct));
        snprintf(value->key_string, KEY_MAX_LENGTH, "%s%d", KEY_PREFIX, index);
        value->number = index;

        error = map_put(mymap, value->key_string, value);
        assert(error==MAP_OK);
    }

    /* Now, check all of the expected values are there */
    for (index=0; index<KEY_COUNT; index+=1)
    {
        snprintf(key_string, KEY_MAX_LENGTH, "%s%d", KEY_PREFIX, index);

        error = map_get(mymap, key_string, (void**)(&value));

        /* Make sure the value was both found and the correct number */
        assert(error==MAP_OK);
        assert(value->number==index);
    }

    /* Make sure that a value that wasn't in the map can't be found */
    snprintf(key_string, KEY_MAX_LENGTH, "%s%d", KEY_PREFIX, KEY_COUNT);

    error = map_get(mymap, key_string, (void**)(&value));

    /* Make sure the value was not found */
    assert(error==MAP_MISSING);

    /* Free all of the values we allocated and remove them from the map */
    for (index=0; index<KEY_COUNT; index+=1)
    {
        snprintf(key_string, KEY_MAX_LENGTH, "%s%d", KEY_PREFIX, index);

        error = map_get(mymap, key_string, (void**)(&value));
        assert(error==MAP_OK);

        error = map_remove(mymap, key_string);
        assert(error==MAP_OK);

        dzn_free(value);
    }

    /* Now, destroy the map */
    map_free(mymap);

    return 1;
}
#endif /* MAP_TEST */
#endif /* DZN_LOCATOR_SERVICES */
