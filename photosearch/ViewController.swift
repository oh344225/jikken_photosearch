//
//  ViewController.swift
//  photosearch
//
//  Created by oshitahayato on 2017/06/13.
//  Copyright © 2017年 oshitahayato. All rights reserved.
//

//ライブラリインポート
import UIKit
import Photos

import HealthKit

//検索用　日付格納のため
var sdate : Date? = Date()
var pulse : Int? = 60

//検索判定ピッカービュー
var pickernum : Int = 0

class ViewController: UIViewController,UIPickerViewDelegate,UIPickerViewDataSource{

	
	//UIcollectionview 写真表示
	@IBOutlet weak var collectionView: UICollectionView!
	
	//UI検索タイプ表示
	@IBOutlet weak var datedisplay: UILabel!
	
	//UIPickerview
	@IBOutlet weak var pickerView: UIPickerView!
	
	var photoAssets: Array! = [PHAsset]()
	
	//healthkit 心拍使用のために用意
	var myHealthStore : HKHealthStore!

	
	override func viewDidLoad() {
		super.viewDidLoad()
		//Hearlthsotre の作成
		myHealthStore = HKHealthStore()
		
		// Delegate設定 検索ピッカー設定
		pickerView.delegate = self
		pickerView.dataSource = self
		
		requestAuthorization()
		setup()
		libraryRequestAuthorization()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	

	
	
	
	////////////////////////////////////////
	//
	//datalist
	private let dataList = ["Full","Date","Pulse","TOP10","Year10"]
	
	// UIPickerViewの列の数
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	// UIPickerViewの行数、要素の全数
	func pickerView(_ pickerView: UIPickerView,
	                numberOfRowsInComponent component: Int) -> Int {
		return dataList.count
	}
	
	// UIPickerViewに表示する配列
	func pickerView(_ pickerView: UIPickerView,
	                titleForRow row: Int,
	                forComponent component: Int) -> String? {
		
		return dataList[row]
	}
	///////////////////////////////////////
	
	//日付変更時に格納するメソッド
	@IBAction func Datepicker(_ sender: UIDatePicker) {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyy-MM-dd"
		sdate = sender.date
		//print(sdate)
		//print(datedisplay.text)
	}
	
	//検索処理選択
	//データ選択時の呼び出しメソッド
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		
		let data1 = dataList[row]
		pickernum = row
		//print("row: \(row)")
		//print("value: \(dataList[row])")
		//print(dataList[row])
		print("選択\(data1) \(pickernum)")
	}
	
	
	
	
	fileprivate func setup() {
		collectionView.dataSource = self
		
		// UICollectionViewCellのマージン等の設定
		let flowLayout: UICollectionViewFlowLayout! = UICollectionViewFlowLayout()
		flowLayout.itemSize = CGSize(width: UIScreen.main.bounds.width / 3 - 4,
		                             height: UIScreen.main.bounds.width / 3 - 4)
		flowLayout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
		flowLayout.minimumInteritemSpacing = 0
		flowLayout.minimumLineSpacing = 6
		
		collectionView.collectionViewLayout = flowLayout
	}
	
	// カメラロールへのアクセス許可
	fileprivate func libraryRequestAuthorization() {
		PHPhotoLibrary.requestAuthorization({ [weak self] status in
			guard let wself = self else {
				return
			}
			switch status {
			case .authorized:
				wself.getAllPhotosInfo()
			case .denied:
				wself.showDeniedAlert()
			case .notDetermined:
				print("NotDetermined")
			case .restricted:
				print("Restricted")
			}
		})
	}
	
	/*
	ボタンイベント
	healthkit アクセス申請
	*/
	
	private func requestAuthorization(){
		
		// 読み込みを許可する型.
		// HKCharacteristicTypeIdentifierDateOfBirthは、readしかできない.
		let typeOfReads = Set(arrayLiteral:
			HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
		                      HKCharacteristicType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!
		)
		
		//  HealthStoreへのアクセス承認をおこなう.
		myHealthStore.requestAuthorization(toShare: nil, read: typeOfReads, completion: { (success, error) in
			if let e = error {
				print("Error: \(e.localizedDescription)")
				return
			}
			print(success ? "Success!" : " Failure!")
		})
	}
	

	
	// カメラロールから全て取得する
	fileprivate func getAllPhotosInfo() {
		var assets: PHFetchResult = PHAsset.fetchAssets(with: .image, options: nil)
		assets.enumerateObjects({ [weak self] (asset, index, stop) -> Void in
			guard let wself = self else {
				return
			}
			wself.photoAssets.append(asset as PHAsset)
		})
		collectionView.reloadData()
		print("写真は\(assets.count)")
		
	}
	
	
	
	// カメラロールへのアクセスが拒否されている場合のアラート
	fileprivate func showDeniedAlert() {
		let alert: UIAlertController = UIAlertController(title: "エラー",
		                                                 message: "「写真」へのアクセスが拒否されています。設定より変更してください。",
		                                                 preferredStyle: .alert)
		let cancel: UIAlertAction = UIAlertAction(title: "キャンセル",
		                                          style: .cancel,
		                                          handler: nil)
		let ok: UIAlertAction = UIAlertAction(title: "設定画面へ",
		                                      style: .default,
		                                      handler: { [weak self] (action) -> Void in
												guard let wself = self else {
													return
												}
												wself.transitionToSettingsApplition()
		})
		alert.addAction(cancel)
		alert.addAction(ok)
		present(alert, animated: true, completion: nil)
	}
	
	fileprivate func transitionToSettingsApplition() {
		let url = URL(string: UIApplicationOpenSettingsURLString)
		if let url = url {
			UIApplication.shared.open(url, options: [:], completionHandler: nil)
		}
	}
	
	
	//カメラロールから日付指定　そこからその日付の心拍の平均より高い写真を表示
	fileprivate func getPulsePhotoInfo(){
	
		//心拍呼び出し
		self.readData()
		
		photoAssets = []
		/*
		// ソート条件を指定
		var options = PHFetchOptions()
		options.sortDescriptors = [
			NSSortDescriptor(key: "creationDate", ascending: false)
		]
		*/
		
		//条件指定 指定した日にちの前後１週間の中から取得
		let options = PHFetchOptions()
		var searchdateplus:Date = Date()
		var searchdateminus:Date = Date()

		//searchdate = self.datedisplay.text
		//searchdate = Date(timeIntervalSinceNow: -46*24*60*60);//一ヶ月前
		//前後１週間を検索
		searchdateplus = Date(timeInterval:+7*24*60*60, since:sdate!)
		searchdateminus = Date(timeInterval:-7*24*60*60, since:sdate!)
		//print(searchdateplus)
		options.predicate = NSPredicate(format: "creationDate <= %@ AND creationDate >= %@", searchdateplus  as CVarArg,searchdateminus as CVarArg)
		options.sortDescriptors = [
			NSSortDescriptor(key: "creationDate", ascending: false)
		]
		
		/*
		//条件指定
		let options = PHFetchOptions()
		var searchdate:Date = Date()
		
		searchdate = Date(timeIntervalSinceNow: -46*24*60*60);//一ヶ月前
		options.predicate = NSPredicate(format: "creationDate >= %@", searchdate as CVarArg)
		options.sortDescriptors = [
		NSSortDescriptor(key: "creationDate", ascending: false)
		]
		
		*/

		//let searchdate = calendar.date(from: self.datedisplay.text)!
		//options.predicate = NSPredicate(format: "creationDate >= %d", searchdate)
		
		
		
		//Photos fetchメソッドから返されたアセットまたはコレクションの順序付きリスト検索結果を格納
		let assets: PHFetchResult = PHAsset.fetchAssets(with: .image, options: options)
		//print(assets)
		//asset格納写真をつくる　検索結果から写真情報抜き出ししてる？？
		assets.enumerateObjects({ (asset, index, stop) -> Void in
			
			//exif読み込み
			let editOptions = PHContentEditingInputRequestOptions()
			editOptions.isNetworkAccessAllowed = true
			
			asset.requestContentEditingInput(with: editOptions, completionHandler: { (contentEditingInput, _) -> Void in
				let url = contentEditingInput!.fullSizeImageURL
				
				//画像nilの条件処理
				if let inputImage:CIImage = CoreImage.CIImage(contentsOf: url!){
					//print("画像:\(inputImage)")
					let meta:NSDictionary? = inputImage.properties as NSDictionary?
					//print("exif:\(meta?["{Exif}"] as? NSDictionary)")
					let exif:NSDictionary? = meta?["{Exif}"] as? NSDictionary
					let text = exif?.object(forKey: kCGImagePropertyExifUserComment) as! String?
					
					//text -> int変換
					if(text == nil){
						//print(text)
					}else{
						// if, guard などを使って切り分ける
						if let p = Int(text!){
							//print(p)
							if(p >= pulse!){
								//print(self.photoAssets)
								self.photoAssets.append(asset as PHAsset)
								print(self.photoAssets.count)
								self.collectionView.reloadData()
							}
						}
						else{
							//print("error")  // --> error
						}
					}
					//////////////////////////
					//print(text)
				}else{
					print("err")
				}
				
				//self.meta = inputImage.properties["{Exif}"] as? NSDictionary
				
				})
			
			//self.photoAssets.append(asset as PHAsset)

		})
		
		print("写真は\(assets.count)")
		//print(photoAssets)
		collectionView.reloadData()

	}
	
	//データ読み出し
	private func readData(){
		
		var error: NSError?
		
		//取得データ・タイプ生成
		let typeOfheartrate = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)

		//日付処理
		let calendar = Calendar.init(identifier: Calendar.Identifier.gregorian)
		let searchdate = sdate!
		let startDate = calendar.startOfDay(for: searchdate)
		let endDate = calendar.date(byAdding: Calendar.Component.day, value: 1, to: startDate)
		
		let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
		// データ読み出し時のオプションを指定(平均値の計算).
		let statsOptions = HKStatisticsOptions.discreteAverage
		
		let staticsQuery = HKStatisticsQuery(quantityType: typeOfheartrate!, quantitySamplePredicate: predicate, options: statsOptions) { (query, result, error) in
			if let e = error {
				print("Error: \(e.localizedDescription)")
				return
			}
			guard let ave = result?.averageQuantity() else {
				print("Error")
				return
			}
			
			// 取得したサンプルを単位に合わせる.
			DispatchQueue.main.async {
				/*
				//ave = 60.0 / ave
				//let p = ave.doubleValue(for: <#T##HKUnit#>)
				print(type(of: ave))
				print("心拍：\(ave)")
				*/
				//心拍int型変換
				let count:HKUnit = HKUnit.count()
				let minute: HKUnit = HKUnit.minute()
				let countPerMinute:HKUnit = count.unitMultiplied(by: minute.reciprocal())
				
				let bpm = ave.doubleValue(for: countPerMinute)
				let intbpm = Int(bpm)
				pulse = intbpm
				//print("心拍：\(intbpm)")
				print(pulse)

			}
		}
		// queryを発行.
		self.myHealthStore.execute(staticsQuery)
	}

	//カメラロールから日付指定　そこからその日付の心拍の平均より高い写真を表示
	fileprivate func getDatePhotoInfo(){
		
		//心拍呼び出し
		self.readData()
		
		photoAssets = []
		
		//条件指定 指定した日にちの前後１週間の中から取得
		let options = PHFetchOptions()
		var searchdateplus:Date = Date()
		var searchdateminus:Date = Date()
		
		//searchdate = self.datedisplay.text
		//searchdate = Date(timeIntervalSinceNow: -46*24*60*60);//一ヶ月前
		//前後１週間を検索
		searchdateplus = Date(timeInterval:+7*24*60*60, since:sdate!)
		searchdateminus = Date(timeInterval:-7*24*60*60, since:sdate!)
		//print(searchdateplus)
		options.predicate = NSPredicate(format: "creationDate <= %@ AND creationDate >= %@", searchdateplus  as CVarArg,searchdateminus as CVarArg)
		options.sortDescriptors = [
			NSSortDescriptor(key: "creationDate", ascending: false)
		]
		
		//Photos fetchメソッドから返されたアセットまたはコレクションの順序付きリスト検索結果を格納
		let assets: PHFetchResult = PHAsset.fetchAssets(with: .image, options: options)
		//print(assets)
		//asset格納写真をつくる　検索結果から写真情報抜き出ししてる？？
		assets.enumerateObjects({ (asset, index, stop) -> Void in
			
			self.photoAssets.append(asset as PHAsset)
		})
		
		print("写真は\(assets.count)")
		//print(photoAssets)
		collectionView.reloadData()
		
	}

	//カメラロールから日付の中から心拍top10検索
	fileprivate func getPulsetop10PhotoInfo(){
		
		//心拍呼び出し
		self.readData()
		
		photoAssets = []
		var pulseList :[Int] = []
		
		//条件指定 指定した日にちの前後１週間の中から取得
		let options = PHFetchOptions()
		var searchdateplus:Date = Date()
		var searchdateminus:Date = Date()
		//前後１週間を検索
		searchdateplus = Date(timeInterval:+7*24*60*60, since:sdate!)
		searchdateminus = Date(timeInterval:-7*24*60*60, since:sdate!)
		//print(searchdateplus)
		options.predicate = NSPredicate(format: "creationDate <= %@ AND creationDate >= %@", searchdateplus  as CVarArg,searchdateminus as CVarArg)
		options.sortDescriptors = [
			NSSortDescriptor(key: "creationDate", ascending: false)
		]
		
		//Photos fetchメソッドから返されたアセットまたはコレクションの順序付きリスト検索結果を格納
		let assets: PHFetchResult = PHAsset.fetchAssets(with: .image, options: options)
		//print(assets)
		
		//asset格納写真からexif読み込み配列格納
		assets.enumerateObjects({ (asset, index, stop) -> Void in
			//exif読み込み
			let editOptions = PHContentEditingInputRequestOptions()
			editOptions.isNetworkAccessAllowed = true
			asset.requestContentEditingInput(with: editOptions, completionHandler: { (contentEditingInput, _) -> Void in
				let url = contentEditingInput!.fullSizeImageURL
				
				//画像nilの条件処理
				if let inputImage:CIImage = CoreImage.CIImage(contentsOf: url!){
					//print("画像:\(inputImage)")
					let meta:NSDictionary? = inputImage.properties as NSDictionary?
					//print("exif:\(meta?["{Exif}"] as? NSDictionary)")
					let exif:NSDictionary? = meta?["{Exif}"] as? NSDictionary
					let text = exif?.object(forKey: kCGImagePropertyExifUserComment) as! String?
					
					//text -> int変換
					if(text == nil){
						//print(text)
					}else{
						// if, guard などを使って切り分ける
						if let p = Int(text!){
							pulseList +=  [p]
							//print(p)
							//print(pulseList)
							pulseList.sort{(val1,val2) -> Bool in
								return val1 > val2
							}
							//print(pulseList)
						}else{
							//print("error")  // --> error
						}
					}
					//////////////////////////
					//print(text)
				}else{
					print("err")
				}
			})
		})
		//asset格納写真からexif読み込み配列格納
		assets.enumerateObjects({ (asset, index, stop) -> Void in
			//exif読み込み
			let editOptions = PHContentEditingInputRequestOptions()
			editOptions.isNetworkAccessAllowed = true
			asset.requestContentEditingInput(with: editOptions, completionHandler: { (contentEditingInput, _) -> Void in
				let url = contentEditingInput!.fullSizeImageURL
				
				//画像nilの条件処理
				if let inputImage:CIImage = CoreImage.CIImage(contentsOf: url!){
					//print("画像:\(inputImage)")
					let meta:NSDictionary? = inputImage.properties as NSDictionary?
					//print("exif:\(meta?["{Exif}"] as? NSDictionary)")
					let exif:NSDictionary? = meta?["{Exif}"] as? NSDictionary
					let text = exif?.object(forKey: kCGImagePropertyExifUserComment) as! String?
					
					//text -> int変換
					if(text == nil){
						//print(text)
					}else{
						// if, guard などを使って切り分ける
						if let p = Int(text!){
							//心拍の高い写真を１回だけ格納するための関数
							var ok = 0
							//心拍top10を１０個比較のための処理
							for i in 0..<10{
								if(p >= pulseList[i]){
									//print(ok)
									//１回だけ格納
									if(ok == 0){
										self.photoAssets.append(asset as PHAsset)
										//print(self.photoAssets.count)
										self.collectionView.reloadData()
										ok += 1
									}
								}
							}
						}else{
							//print("error")  // --> error
						}
					}
					//////////////////////////
					//print(text)
				}else{
					print("err")
				}
			})
		})
		//print(pulseList)
		print("写真は\(assets.count)")
		//print(photoAssets)
		collectionView.reloadData()
	}

	
	fileprivate func getPulseYear10PhotoInfo(){
		
		//心拍呼び出し
		self.readData()
		
		photoAssets = []
		var pulseList :[Int] = []
		
		//条件指定 指定した日にちの前後１週間の中から取得
		let options = PHFetchOptions()
		var searchdateplus:Date = Date()
		var searchdateminus:Date = Date()
		//前後１週間を検索
		searchdateplus = Date(timeInterval:+0, since:sdate!)
		searchdateminus = Date(timeInterval:-365*24*60*60, since:sdate!)
		//print(searchdateplus)
		options.predicate = NSPredicate(format: "creationDate <= %@ AND creationDate >= %@", searchdateplus  as CVarArg,searchdateminus as CVarArg)
		options.sortDescriptors = [
			NSSortDescriptor(key: "creationDate", ascending: false)
		]
		
		//Photos fetchメソッドから返されたアセットまたはコレクションの順序付きリスト検索結果を格納
		let assets: PHFetchResult = PHAsset.fetchAssets(with: .image, options: options)
		//print(assets)
		
		//asset格納写真からexif読み込み配列格納
		assets.enumerateObjects({ (asset, index, stop) -> Void in
			//exif読み込み
			let editOptions = PHContentEditingInputRequestOptions()
			editOptions.isNetworkAccessAllowed = true
			asset.requestContentEditingInput(with: editOptions, completionHandler: { (contentEditingInput, _) -> Void in
				let url = contentEditingInput!.fullSizeImageURL
				
				//画像nilの条件処理
				if let inputImage:CIImage = CoreImage.CIImage(contentsOf: url!){
					//print("画像:\(inputImage)")
					let meta:NSDictionary? = inputImage.properties as NSDictionary?
					//print("exif:\(meta?["{Exif}"] as? NSDictionary)")
					let exif:NSDictionary? = meta?["{Exif}"] as? NSDictionary
					let text = exif?.object(forKey: kCGImagePropertyExifUserComment) as! String?
					
					//text -> int変換
					if(text == nil){
						//print(text)
					}else{
						// if, guard などを使って切り分ける
						if let p = Int(text!){
							pulseList +=  [p]
							//print(p)
							//print(pulseList)
							pulseList.sort{(val1,val2) -> Bool in
								return val1 > val2
							}
							//print(pulseList)
						}else{
							//print("error")  // --> error
						}
					}
					//////////////////////////
					//print(text)
				}else{
					print("err")
				}
			})
		})
		//asset格納写真からexif読み込み配列格納
		assets.enumerateObjects({ (asset, index, stop) -> Void in
			//exif読み込み
			let editOptions = PHContentEditingInputRequestOptions()
			editOptions.isNetworkAccessAllowed = true
			asset.requestContentEditingInput(with: editOptions, completionHandler: { (contentEditingInput, _) -> Void in
				let url = contentEditingInput!.fullSizeImageURL
				
				//画像nilの条件処理
				if let inputImage:CIImage = CoreImage.CIImage(contentsOf: url!){
					//print("画像:\(inputImage)")
					let meta:NSDictionary? = inputImage.properties as NSDictionary?
					//print("exif:\(meta?["{Exif}"] as? NSDictionary)")
					let exif:NSDictionary? = meta?["{Exif}"] as? NSDictionary
					let text = exif?.object(forKey: kCGImagePropertyExifUserComment) as! String?
					
					//text -> int変換
					if(text == nil){
						print(text)
					}else{
						// if, guard などを使って切り分ける
						if let p = Int(text!){
							//心拍の高い写真を１回だけ格納するための関数
							var ok = 0
							//心拍top10を１０個比較のための処理
							for i in 0..<10{
								if(p >= pulseList[i]){
									//print(ok)
									//１回だけ格納
									if(ok == 0){
										self.photoAssets.append(asset as PHAsset)
										//print(self.photoAssets.count)
										self.collectionView.reloadData()
										ok += 1
									}
								}
							}
						}else{
							//print("error")  // --> error
						}
					}
					//////////////////////////
					//print(text)
				}else{
					print("err")
				}
			})
		})
		//print(pulseList)
		print("写真は\(assets.count)")
		//print(photoAssets)
		collectionView.reloadData()
	}


	//検索実行
	@IBAction func Searchbutton(_ sender: Any){
		
		//実行タイム計算
		let beforeTime = NSDate()
		
		

		
		// 時間を計測したい処理を記述
		if(pickernum == 0){
			getAllPhotosInfo()
			datedisplay.text = "Full"
		}
		if(pickernum == 1){
			getDatePhotoInfo()
			datedisplay.text = "Date"
			//print("okkkkk")
		}
		if(pickernum == 2){
			getPulsePhotoInfo()
			datedisplay.text = "Pulse"
		}
		if(pickernum == 3){
			getPulsetop10PhotoInfo()
			datedisplay.text = "Top10"
		}
		if(pickernum == 4){
			getPulseYear10PhotoInfo()
			datedisplay.text = "Year10"
		}

	
		let currentTime = NSDate()
		// 経過時間の取得
		let pastTime = currentTime.timeIntervalSince(beforeTime as Date)
		print("pastTime: \(pastTime)")
	
	}



}

//拡張、collectionviewの拡張＞名前はそのままにプロパティやメソッドの追加ができる
extension ViewController : UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return photoAssets.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CameraRollCollectionViewCell
		cell.setConfigure(assets: photoAssets[indexPath.row])
		return cell
	}
}
