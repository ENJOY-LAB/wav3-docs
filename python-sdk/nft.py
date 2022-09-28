from transaction import Account, FaucetClient, RestClient, TESTNET_URL, FAUCET_URL, ENJOY_URL
import secret

nft_contract = "0x0bf137ced519f68a3ac97eee8007712eeb7c5c982ebf9c79aed9666627a44aaa"

class NFTClient(RestClient):


    def __init__(self, node_url, creator, name, description, maximum, mutate_setting, 
        symbol, image_uri, animation_uri, website, standard_version, 
        commercial_standard, royalty_policy, multi_edition):
        super().__init__(node_url)
        self.creator = creator
        self.name = name
        self.description = description
        self.maximum = maximum
        self.mutate_setting = mutate_setting
        self.symbol = symbol
        self.image_uri = image_uri
        self.animation_uri = animation_uri
        self.website = website
        self.standard_version = standard_version
        self.commercial_standard = commercial_standard
        self.royalty_policy = royalty_policy
        self.multi_edition = multi_edition

    def create_collection(self, creator_signer):
        payload = {
            "type": "entry_function_payload",
            "function": f"{nft_contract}::NFT::create_collection",
            "type_arguments": [],
            "arguments": [
                self.name,
                self.description,
                str(self.maximum),
                self.mutate_setting,
                self.symbol,
                self.image_uri,
                self.animation_uri,
                self.website,
                str(self.standard_version),
                self.commercial_standard,
                self.royalty_policy,
                self.multi_edition
            ]
        }
        res = self.execute_transaction_with_payload(creator_signer, payload)
        return str(res["hash"])
    
    def create_tokendata(self, creator_signer, token_name, description, maximum, royalty_payee, royalty_denominator, 
        royalty_numerator, token_mutate_setting, properties_keys, properties_values, properties_types, image_uri, animation_uri, image_checksum, mutate_setting):
        payload = {
            "type": "entry_function_payload",
            "function": f"{nft_contract}::NFT::create_tokendata",
            "type_arguments": [],
            "arguments": [
                self.name,
                token_name,
                description,
                str(maximum),
                royalty_payee,
                str(royalty_denominator),
                str(royalty_numerator),
                token_mutate_setting,
                properties_keys,
                properties_values,
                properties_types,
                image_uri,
                animation_uri,
                str(image_checksum),
                mutate_setting
            ]
        }
        res = self.execute_transaction_with_payload(creator_signer, payload)
        return str(res["hash"])

    def mint_nft(self, creator_signer, token_name, properties):
        payload = {
            "type": "entry_function_payload",
            "function": f"{nft_contract}::NFT::mint_nft",
            "type_arguments": [],
            "arguments": [
                self.name,
                token_name,
                properties
            ]
        }
        res = self.execute_transaction_with_payload(creator_signer, payload)
        return str(res["hash"])

    def add_social_media(self, creator_signer, social_media_type, social_media):
        payload = {
            "type": "entry_function_payload",
            "function": f"{nft_contract}::NFT::add_social_media",
            "type_arguments": [],
            "arguments": [
                self.name,
                social_media_type,
                social_media
            ]
        }
        print(payload)
        res = self.execute_transaction_with_payload(creator_signer, payload)
        return str(res["hash"])

    def update_social_media(self, creator_signer, social_media_type, social_media):
        payload = {
            "type": "entry_function_payload",
            "function": f"{nft_contract}::NFT::update_social_media",
            "type_arguments": [],
            "arguments": [
                self.name,
                social_media_type,
                social_media
            ]
        }
        res = self.execute_transaction_with_payload(creator_signer, payload)
        return str(res["hash"])


if __name__ == "__main__":

    creator_private_key = secret.get_private_key("example")
    creator_signer = Account(bytes.fromhex(creator_private_key))
    creator_address = secret.get_public_key("example")
    nft_collection = {
        "creator_address": creator_address,
        "collection_name": "nft gensis",
        "description": "This is genesis NFT in Aptos!",
        "maximum": 0,
        "mutate_setting": [True, True, True],
        "symbol": "NFT",
        "image_uri": "https://uqfwqgtjpx3r2gtez43hskakruvisr7g5penbijtjkup7rcr3bxq.arweave.net/pAtoGml99x0aZM82eSgKjSqJR-bryNChM0qo_8RR2G8",
        "animation_uri": "https://smuq6hdklbitp6az6fliwsqppilazfsadsicbnm7g4lmw43b5cqa.arweave.net/kykPHGpYUTf4GfFWi0oPehYMlkAckCC1nzcWy3Nh6KA",
        "website": "https://www.miumiugekacha.com",
        "standard_version": 0,
        "commercial_standard": "CC0",
        "royalty_policy": "X2Y2",
        "multi_edition": False,
        "social_media": {
            "twitter": "https://twitter.com/aptos_wave",
        }
    }

    token = {
        "token_name": "cat #2", 
        "description": "second nft", 
        "maximum": 1, 
        "royalty_payee": nft_contract, 
        "royalty_denominator": 100, 
        "royalty_numerator": 20, 
        "token_mutate_setting": [True, True, True, True, True],
        "properties_keys": ["author", "point", "properties"],
        "properties_values": ["Wav3 Labs".encode("utf-8").hex(), "0".encode("utf-8").hex(), "empty".encode("utf-8").hex()],
        "properties_types": ["string", "integer", "string"],
        "image_uri": "https://mrkh2hy3iryvd4a246rgo5bvcflehxgtg4naiihgvyrbk4ckumga.arweave.net/ZFR9HxtEcVHwGueiZ3Q1EVZD3NM3GgQg5q4iFXBKoww",
        "animation_uri": "https://smuq6hdklbitp6az6fliwsqppilazfsadsicbnm7g4lmw43b5cqa.arweave.net/kykPHGpYUTf4GfFWi0oPehYMlkAckCC1nzcWy3Nh6KA",
        "image_checksum": 0, 
        "mutate_setting": [False]
    }
    # create collection
    nft_client = NFTClient(
        TESTNET_URL, 
        nft_collection["creator_address"], 
        nft_collection["collection_name"],
        nft_collection["description"],
        nft_collection["maximum"],
        nft_collection["mutate_setting"],
        nft_collection["symbol"], 
        nft_collection["image_uri"], 
        nft_collection["animation_uri"], 
        nft_collection["website"], 
        nft_collection["standard_version"], 
        nft_collection["commercial_standard"],
        nft_collection["royalty_policy"], 
        nft_collection["multi_edition"]
        )
    # txn_hash = nft_client.create_collection(creator_signer)
    # nft_client.wait_for_transaction(txn_hash)

    # # create token data
    # txn_hash = nft_client.create_tokendata(
    #     creator_signer, 
    #     token["token_name"],
    #     token["description"],
    #     token["maximum"],
    #     token["royalty_payee"],
    #     token["royalty_denominator"],
    #     token["royalty_numerator"],
    #     token["token_mutate_setting"],
    #     token["properties_keys"],
    #     token["properties_values"],
    #     token["properties_types"],
    #     token["image_uri"],
    #     token["animation_uri"],
    #     token["image_checksum"],
    #     token["mutate_setting"]
    #     )

    # nft_client.wait_for_transaction(txn_hash)
    # print(txn_hash)

    # properties = {
    #     "1155": {
    #         "simple_property": "example value",
	# 	"rich_property": {
	# 		"name": "Name",
	# 		"value": "123",
	# 		"display_value": "123 Example Value",
	# 		"class": "emphasis",
	# 		"css": {
	# 			"color": "#ffffff",
	# 			"font-weight": "bold",
	# 			"text-decoration": "underline"
	# 		}
	# 	},
	# 	"array_property": {
	# 		"name": "Name",
	# 		"value": [1,2,3,4],
	# 		"class": "emphasis"
	# 	}
    #     }
    # }
    # txn_hash = nft_client.mint_nft(creator_signer, token["token_name"], str(properties["1155"]))

    # nft_client.wait_for_transaction(txn_hash)
    # print(txn_hash)

    # txn_hash = nft_client.add_social_media(creator_signer, "twitter", nft_collection["social_media"]["twitter"])
    # nft_client.wait_for_transaction(txn_hash)
    # print(txn_hash)

    txn_hash = nft_client.update_social_media(creator_signer, "twitter", nft_collection["social_media"]["twitter"])
    nft_client.wait_for_transaction(txn_hash)
    print(txn_hash)