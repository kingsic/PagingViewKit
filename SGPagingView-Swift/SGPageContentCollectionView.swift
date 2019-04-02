//
//  SGPageContentCollectionView.swift
//  SGPagingViewSwiftExample
//
//  Created by kingsic on 2018/9/12.
//  Copyright © 2018年 kingsic. All rights reserved.
//

import UIKit

@objc protocol SGPageContentCollectionViewDelegate: NSObjectProtocol {
    /**
     *  联动 SGPageTitleView 的方法
     *
     *  @param pageContentCollectionView      SGPageContentCollectionView
     *  @param progress             SGPageContentCollectionView 内部视图滚动时的偏移量
     *  @param originalIndex        原始视图所在下标
     *  @param targetIndex          目标视图所在下标
     */
    @objc optional func pageContentCollectionView(pageContentCollectionView: SGPageContentCollectionView, progress: CGFloat, originalIndex: Int, targetIndex: Int)
    
    /**
     *  获取 SGPageContentCollectionView 当前子控制器的下标值
     *
     *  @param pageContentCollectionView     SGPageContentCollectionView
     *  @param index                         SGPageContentCollectionView 当前子控制器的下标值
     */
    @objc optional func pageContentCollectionView(pageContentCollectionView: SGPageContentCollectionView, index: Int)
    
    /// SGPageContentCollectionView 内容开始拖拽方法
    @objc optional func pageContentCollectionViewWillBeginDragging()
    /// SGPageContentCollectionView 内容结束拖拽方法
    @objc optional func pageContentCollectionViewDidEndDecelerating()
}

private let cellID = "cellID"

class SGPageContentCollectionView: UIView {
    /**
     *  拓展 init 方法
     *
     *  @param frame        frame
     *  @param parentVC     当前控制器
     *  @param childVCs     子控制器个数
     */
    init(frame: CGRect, parentVC: UIViewController, childVCs: [UIViewController]) {
        super.init(frame: frame)
        self.parentVC = parentVC
        self.childVCs = childVCs
        self.setupSubViews()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 给外界提供的属性
    /// SGPageContentCollectionViewDelegate
    weak var delegateCollectionView: SGPageContentCollectionViewDelegate?
    /// SGPageContentCollectionView 是否可以滚动，默认为 true
    var isScrollEnabled: Bool = true
    /// 点击标题触发动画切换滚动内容，默认为 false
    var isAnimated: Bool = false
    
    // MARK: - 私有属性
    private weak var parentVC: UIViewController?
    private var childVCs: [UIViewController] = []
    private var startOffsetX: CGFloat = 0.0
    private var previousCVCIndex: Int = -1
    private var scroll: Bool? = false
    
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = self.bounds.size
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .horizontal
        
        let rect = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        let collectionView = UICollectionView(frame: rect, collectionViewLayout: flowLayout)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.bounces = false
        collectionView.backgroundColor = UIColor.white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellID)
        return collectionView
    }()
}

// MARK: - 给外界提供的方法
extension SGPageContentCollectionView {
    /// 根据 SGPageTitleView 标题选中时的下标并显示相应的子控制器
    func setPageContentCollectionView(index: Int) {
        let offsetX = CGFloat(index) * collectionView.frame.size.width
        startOffsetX = offsetX
        if previousCVCIndex != index {
            collectionView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: isAnimated)
        }
        previousCVCIndex = index
        if (delegateCollectionView != nil) && (delegateCollectionView?.responds(to: #selector(delegateCollectionView?.pageContentCollectionView(pageContentCollectionView:index:))))! {
            delegateCollectionView?.pageContentCollectionView!(pageContentCollectionView: self, index: index)
        }
    }
}

// Mark: - 添加子控件
extension SGPageContentCollectionView {
    private func setupSubViews() {
        let tempView = UIView()
        self.addSubview(tempView)
        self.addSubview(self.collectionView)
    }
}

// MARK: - UICollectionView - 数据源方法
extension SGPageContentCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return childVCs.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath)
        cell.contentView.subviews.forEach { (subView) in
            subView.removeFromSuperview()
        }
        let childVC = childVCs[indexPath.item]
        parentVC?.addChild(childVC)
        cell.contentView.addSubview(childVC.view)
        childVC.view.frame = cell.contentView.frame
        childVC.didMove(toParent: parentVC)
        return cell
    }
}

// MARK: - UIScrollView - 代理方法
extension SGPageContentCollectionView {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        startOffsetX = scrollView.contentOffset.x
        scroll = true
        if (delegateCollectionView != nil) && (delegateCollectionView?.responds(to: #selector(delegateCollectionView?.pageContentCollectionViewWillBeginDragging)))! {
            delegateCollectionView?.pageContentCollectionViewWillBeginDragging!()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scroll = false
        let offsetX = scrollView.contentOffset.x
        previousCVCIndex = Int(offsetX / scrollView.frame.size.width)
        if (delegateCollectionView != nil) && (delegateCollectionView?.responds(to: #selector(delegateCollectionView?.pageContentCollectionView(pageContentCollectionView:index:))))! {
            delegateCollectionView?.pageContentCollectionView!(pageContentCollectionView: self, index: previousCVCIndex)
        }
        if (delegateCollectionView != nil) && (delegateCollectionView?.responds(to: #selector(delegateCollectionView?.pageContentCollectionViewDidEndDecelerating)))! {
            delegateCollectionView?.pageContentCollectionViewDidEndDecelerating!()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isAnimated == true && scroll == false {
            return
        }
        // 1、定义获取需要的数据
        var progress: CGFloat = 0.0
        var originalIndex: Int = 0
        var targetIndex: Int = 0

        // 2、判断是左滑还是右滑
        let currentOffsetX: CGFloat = scrollView.contentOffset.x
        let scrollViewW: CGFloat = scrollView.bounds.size.width
        if currentOffsetX > startOffsetX { // 左滑
            // 1、计算 progress
            progress = currentOffsetX / scrollViewW - floor(currentOffsetX / scrollViewW);
            // 2、计算 originalIndex
            originalIndex = Int(currentOffsetX / scrollViewW);
            // 3、计算 targetIndex
            targetIndex = originalIndex + 1;
            if targetIndex >= childVCs.count {
                progress = 1;
                targetIndex = originalIndex;
            }
            // 4、如果完全划过去
            if currentOffsetX - startOffsetX == scrollViewW {
                progress = 1;
                targetIndex = originalIndex;
            }
        } else { // 右滑
            // 1、计算 progress
            progress = 1 - (currentOffsetX / scrollViewW - floor(currentOffsetX / scrollViewW));
            // 2、计算 targetIndex
            targetIndex = Int(currentOffsetX / scrollViewW);
            // 3、计算 originalIndex
            originalIndex = targetIndex + 1;
            if originalIndex >= childVCs.count {
                originalIndex = childVCs.count - 1;
            }
        }
   
        if (delegateCollectionView != nil) && (delegateCollectionView?.responds(to: #selector(delegateCollectionView?.pageContentCollectionView(pageContentCollectionView:progress:originalIndex:targetIndex:))))! {
            delegateCollectionView?.pageContentCollectionView!(pageContentCollectionView: self, progress: progress, originalIndex: originalIndex, targetIndex: targetIndex)
        }
    }
}

