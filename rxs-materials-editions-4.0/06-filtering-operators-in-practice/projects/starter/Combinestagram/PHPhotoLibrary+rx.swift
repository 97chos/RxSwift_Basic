//
//  PHPhotoLibrary+rx.swift
//  Combinestagram
//
//  Created by sangho Cho on 2021/01/14.
//  Copyright © 2021 Underplot ltd. All rights reserved.
//

import Foundation
import RxSwift
import Photos

extension PHPhotoLibrary {
  static var autorized: Observable<Bool> = {
    return Observable.create{ observer in
      DispatchQueue.main.async {
        if authorizationStatus() == .authorized {
          observer.onNext(true)
          observer.onCompleted()
        } else {
          observer.onNext(false)
          requestAuthorization { newStatus in
            observer.onNext(newStatus == .authorized)
            observer.onCompleted()
          }
        }
      }
      return Disposables.create()
    }
  }()


}
