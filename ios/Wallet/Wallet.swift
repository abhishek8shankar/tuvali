import Foundation
import Gzip

@objc(Wallet)
@available(iOS 13.0, *)
class Wallet: NSObject {

    static let shared = Wallet()
    var central: Central?
    var secretTranslator: SecretTranslator?
    var cryptoBox: WalletCryptoBox = WalletCryptoBoxBuilder().build()
    var advIdentifier: String?
    var verifierPublicKey: Data?
    static let EXCHANGE_RECEIVER_INFO_DATA = "{\"deviceName\":\"wallet\"}"

    private override init() {
        super.init()
    }

    @objc(getModuleName:withRejecter:)
    func getModuleName(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        resolve(["iOS Wallet"])
    }

    func setAdvIdentifier(identifier: String) {
        self.advIdentifier = identifier
    }

    func setVerifierPublicKey(publicKeyData: Data) {
        verifierPublicKey = publicKeyData
    }

    func destroyConnection(){
        onDeviceDisconnected(isManualDisconnect: false)
    }

    func isSameAdvIdentifier(advertisementPayload: Data) -> Bool {
        guard let advIdentifier = advIdentifier else {
            os_log("Found NO ADV Identifier")
            return false
        }
        let advIdentifierData = hexStringToData(string: advIdentifier)
        if advIdentifierData == advertisementPayload {
            return true
        }
        return false
    }

    func hexStringToData(string: String) -> Data {
        let stringArray = Array(string)
        var data: Data = Data()
        for i in stride(from: 0, to: string.count, by: 2) {
            let pair: String = String(stringArray[i]) + String(stringArray[i+1])
            if let byteNum = UInt8(pair, radix: 16) {
                let byte = Data([byteNum])
                data.append(byte)
            } else {
                fatalError()
            }
        }
        return data
    }

    func sendData(data: String) {
        var dataInBytes = Data(data.utf8)
        var compressedBytes = try! dataInBytes.gzipped()
        var encryptedData = secretTranslator?.encryptToSend(data: compressedBytes)

        if (encryptedData != nil) {
            //print("Complete Encrypted Data: \(encryptedData!.toHex())")
            print("Sha256 of Encrypted Data: \(encryptedData!.sha256())")
            DispatchQueue.main.async {
                let transferHandler = TransferHandler.shared
                // DOUBT: why is encrypted data written twice ?
                self.central?.delegate = transferHandler
                transferHandler.initialize(initdData: encryptedData!)
                var currentMTUSize =  Central.shared.connectedPeripheral?.maximumWriteValueLength(for: .withoutResponse)
                if currentMTUSize == nil || currentMTUSize! < 0 {
                   currentMTUSize = BLEConstants.DEFAULT_CHUNK_SIZE
                }
                let imsgBuilder = imessage(msgType: .INIT_RESPONSE_TRANSFER, data: encryptedData!, mtuSize: currentMTUSize)
                transferHandler.sendMessage(message: imsgBuilder)
            }
        }
    }

    func writeToIdentifyRequest() {
        print("::: write identify called ::: ")
        let publicKey = self.cryptoBox.getPublicKey()
        print("verifier pub key:::", self.verifierPublicKey)
        guard let verifierPublicKey = self.verifierPublicKey else {
            os_log("Write Identify - Found NO KEY")
            return
        }
        secretTranslator = (cryptoBox.buildSecretsTranslator(verifierPublicKey: verifierPublicKey))
        var iv = (self.secretTranslator?.initializationVector())!
        central?.write(serviceUuid: Peripheral.SERVICE_UUID, charUUID: NetworkCharNums.IDENTIFY_REQUEST_CHAR_UUID, data: iv + publicKey)
    }

    func onDeviceDisconnected(isManualDisconnect: Bool) {
        if(!isManualDisconnect) {
            if let connectedPeripheral = central?.connectedPeripheral {
                central?.centralManager.cancelPeripheralConnection(connectedPeripheral)
            }
            EventEmitter.sharedInstance.emitNearbyEvent(event: "onDisconnected")
        }
    }
}
extension Wallet: WalletProtocol {
    func onIdentifyWriteSuccess() {
        EventEmitter.sharedInstance.emitNearbyMessage(event: "exchange-receiver-info", data: Self.EXCHANGE_RECEIVER_INFO_DATA)
        print("wallet delegate called")
    }

    func onDisconnectStatusChange(data: Data?){
        print("Handling notification for disconnect handle")
        if let data {
            let connStatusID = Int(data[0])
            if connStatusID == 1 {
                print("con statusid:", connStatusID)
                destroyConnection()
            }
        } else {
            print("weird reason!!")
        }
    }
}
