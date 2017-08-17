//
//  ViewController.swift
//  photosearch
//
//  Created by oshitahayato on 2017/06/13.
//  Copyright © 2017年 oshitahayato. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController{

	
	
	@IBOutlet weak var collectionView: UICollectionView!
	
	@IBOutlet weak var datedisplay: UILabel!

	//日付変更時に格納するメソッド
	@IBAction func Datepicker(_ sender: UIDatePicker) {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyy/MM/dd"
		datedisplay.text = formatter.string(from: sender.date)
	}
	
	
	var photoAssets: Array! = [PHAsset]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setup()
		libraryRequestAuthorization()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
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
	
	
	//未完成 写真が新しい順にして表示させる。
	//カメラロールから日付　指定して、取得
	fileprivate func getselectPhotoInfo(){
		photoAssets = []
		// ソート条件を指定
		var options = PHFetchOptions()
		options.sortDescriptors = [
			NSSortDescriptor(key: "creationDate", ascending: false)
		]
		
		var assets: PHFetchResult = PHAsset.fetchAssets(with: .image, options: options)
		assets.enumerateObjects({ (asset, index, stop) -> Void in
			self.photoAssets.append(asset as PHAsset)
		})
		collectionView.reloadData()
		//print(photoAssets)
		
	}

	//検索実行
	@IBAction func Searchbutton(_ sender: Any) {
		getselectPhotoInfo()
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
