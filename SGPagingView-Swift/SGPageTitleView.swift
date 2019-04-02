//
//  SGPageTitleView.swift
//  SGPagingViewSwiftExample
//
//  Created by kingsic on 2018/9/12.
//  Copyright © 2018年 kingsic. All rights reserved.
//

import UIKit

class SGPageTitleButton: UIButton {
}

protocol SGPageTitleViewDelegate : NSObjectProtocol {
    /// index 当前选中标题对应的下标值
    func pageTitleView(pageTitleView: SGPageTitleView, index: Int)
}

class SGPageTitleView: UIView {
    // MARK: - 给外界属性
    /// 选中标题按钮下标，默认为 0
    var index: Int = 0
    /// 重置选中标题按钮下标（用于子控制器内的点击事件改变标题的选中下标）
    var resetIndex: Int?
    /// 拓展 init 方法
    init(frame: CGRect, delegate: SGPageTitleViewDelegate, titleNames: [String], configure: SGPageTitleViewConfigure) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white.withAlphaComponent(0.77)
        self.delegateTitleView = delegate
        self.titleNames = titleNames
        self.configure = configure
        self.setupSubviews()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 私有属性
    private weak var delegateTitleView : SGPageTitleViewDelegate?
    private var titleNames: [String] = []
    private var configure: SGPageTitleViewConfigure!
    private var allTitleTextWidth: CGFloat = 0.0
    private var allWidth: CGFloat = 0.0
    private var btnMArr:[SGPageTitleButton] = []
    private var tempBtn: UIButton?
    private var signBtnIndex: Int = 0
    private var signBtnClick: Bool = false
    /// 开始颜色, 取值范围 0~1
    private var startR: CGFloat = 0.0
    private var startG: CGFloat = 0.0
    private var startB: CGFloat = 0.0
    /// 完成颜色, 取值范围 0~1
    private var endR: CGFloat = 0.0
    private var endG: CGFloat = 0.0
    private var endB: CGFloat = 0.0
    
    // MARK: - layoutSubviews
    override func layoutSubviews() {
        super.layoutSubviews()
        P_btn_action(button: btnMArr[index])
    }

    // MARK: - 懒加载子控件
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.frame = CGRect(x: 0, y:0, width: self.frame.size.width, height: self.frame.size.height)
        if (self.configure.needBounces == false) {
            scrollView.bounces = false
        }
        return scrollView
    }()
    private lazy var bottomSeparator: UIView = {
        let bottomSeparator = UIView()
        let size = self.frame.size
        let height: CGFloat = 0.5
        bottomSeparator.frame = CGRect(x: 0, y: size.height - height, width: size.width, height: height)
        bottomSeparator.backgroundColor = configure.bottomSeparatorColor
        return bottomSeparator
    }()
    private lazy var indicator: UIView = {
        let indicator = UIView()
        indicator.backgroundColor = configure.indicatorColor
        if configure.indicatorStyle == .Cover {
            let tempSize = self.P_size(string: btnMArr[0].currentTitle!, font: self.configure.titleFont)
            let tempIndicatorHeight = tempSize.height
            if configure.indicatorHeight > self.frame.size.height {
                indicator.frame.origin.y = 0
                indicator.frame.size.height = self.frame.size.height
            } else if configure.indicatorHeight < tempIndicatorHeight {
                indicator.frame.origin.y = 0.5 * (self.frame.size.height - tempIndicatorHeight)
                indicator.frame.size.height = tempIndicatorHeight
            } else {
                indicator.frame.origin.y = 0.5 * (self.frame.size.height - configure.indicatorHeight)
                indicator.frame.size.height = configure.indicatorHeight
            }
            // 边框宽度及边框颜色
            indicator.layer.borderWidth = configure.indicatorBorderWidth
            indicator.layer.borderColor = configure.indicatorBorderColor.cgColor

        } else {
            let indicatorHeight = configure.indicatorHeight
            indicator.frame.size.height = indicatorHeight
            indicator.frame.origin.y = self.frame.size.height - indicatorHeight - configure.indicatorToBottomDistance
        }
        // 圆角处理
        if configure.indicatorCornerRadius > 0.5 * indicator.frame.size.height {
            indicator.layer.cornerRadius = 0.5 * indicator.frame.size.height
        } else {
            indicator.layer.cornerRadius = configure.indicatorCornerRadius
        }
        return indicator
    }()
}

// MARK: - 添加子控件
extension SGPageTitleView {
    private func setupSubviews() {
        let tempView = UIView()
        self.addSubview(tempView)
        self.addSubview(self.scrollView)
        self.setupTitleButtons()
        // 添加底部分割线
        if (configure.showBottomSeparator) {
            self.addSubview(self.bottomSeparator)
        }
        // 添加指示器
        if (configure.showIndicator) {
            self.scrollView.insertSubview(self.indicator, at: 0)
        }
    }
}

// MARK: - 添加标题按钮
extension SGPageTitleView {
    private func setupTitleButtons() {
        let titleCount = titleNames.count
        let selfSize = self.frame.size

        titleNames.forEach { (title) in
            allTitleTextWidth += P_size(string: title, font: configure.titleFont).width
        }
        // 所有标题文字宽度 ＋ 按钮之间的间隔
        allWidth = CGFloat(ceilf(Float(allTitleTextWidth + configure.titleAdditionalWidth * CGFloat(titleCount))))
        let VSeparatorW: CGFloat = 1.0
        var VSeparatorH: CGFloat = selfSize.height - configure.verticalSeparatorReduceHeight
        if VSeparatorH <= 0 {
            VSeparatorH = selfSize.height
        }
        let VSeparatorY: CGFloat = 0.5 * (selfSize.height - VSeparatorH)
        
        if allWidth <= selfSize.width { /// CoatTitleView 静止样式
            let btnY: CGFloat = 0
            let btnW: CGFloat = self.frame.size.width / CGFloat(titleCount)
            var btnH: CGFloat = 0.0
            if configure.indicatorStyle == .Default {
                btnH = selfSize.height - configure.indicatorHeight
            } else {
                btnH = selfSize.height
            }
            for index in 0..<titleCount {
                let btn = SGPageTitleButton()
                let btnX = btnW * CGFloat(index)
                btn.frame = CGRect(x: btnX, y: btnY, width: btnW, height: btnH)
                btn.tag = index
                btn.titleLabel?.font = configure.titleFont
                btn.setTitle(titleNames[index], for: .normal)
                btn.setTitleColor(configure.titleColor, for: .normal)
                btn.setTitleColor(configure.titleSelectedColor, for: .selected)
                btn.addTarget(self, action: #selector(P_btn_action(button:)), for: .touchUpInside)
                btnMArr.append(btn)
                scrollView.addSubview(btn)
                
                // 2、添加按钮之间的分割线
                if configure.showVerticalSeparator {
                    let VSeparator = UIView()
                    if index != 0 {
                        let VSeparatorX = btnW * CGFloat(index) - 0.5
                        VSeparator.frame = CGRect(x: VSeparatorX, y: VSeparatorY, width: VSeparatorW, height: VSeparatorH)
                        VSeparator.backgroundColor = configure.verticalSeparatorColor
                        scrollView.addSubview(VSeparator)
                    }
                }
            }
            scrollView.contentSize = CGSize(width: selfSize.width, height: selfSize.height)

        } else { /// CoatTitleView 滚动样式
            var btnX: CGFloat = 0.0
            let btnY: CGFloat = 0.0
            var btnH: CGFloat = 0.0
            if configure.indicatorStyle == .Default {
                btnH = selfSize.height - configure.indicatorHeight
            } else {
                btnH = selfSize.height
            }
            let VSeparatorW: CGFloat = 1.0
            var VSeparatorH: CGFloat = selfSize.height - configure.verticalSeparatorReduceHeight
            if (VSeparatorH <= 0) {
                VSeparatorH = selfSize.height
            }
            let VSeparatorY = 0.5 * (selfSize.height - VSeparatorH)

            for index in 0..<titleCount {
                let btn = SGPageTitleButton()
                let tempSize = P_size(string: titleNames[index], font: configure.titleFont)
                let btnW: CGFloat = tempSize.width + configure.titleAdditionalWidth
                btn.frame = CGRect(x: btnX, y: btnY, width: btnW, height: btnH)
                btnX = btnX + btnW
                btn.tag = index
                btn.titleLabel?.font = configure.titleFont
                btn.setTitle(titleNames[index], for: .normal)
                btn.setTitleColor(configure.titleColor, for: .normal)
                btn.setTitleColor(configure.titleSelectedColor, for: .selected)
                btn.addTarget(self, action: #selector(P_btn_action(button:)), for: .touchUpInside)
                btnMArr.append(btn)
                scrollView.addSubview(btn)
                
                // 2、添加按钮之间的分割线
                if configure.showVerticalSeparator {
                    let VSeparator = UIView()
                    if index < titleCount - 1 {
                        let VSeparatorX = btnX - 0.5
                        VSeparator.frame = CGRect(x: VSeparatorX, y: VSeparatorY, width: VSeparatorW, height: VSeparatorH)
                        VSeparator.backgroundColor = configure.verticalSeparatorColor
                        scrollView.addSubview(VSeparator)
                    }
                }
            }
            let scrollViewWidth: CGFloat = (scrollView.subviews.last?.frame.maxX)!
            scrollView.contentSize = CGSize(width: scrollViewWidth, height: self.frame.size.height)
        }
        
        // 标题文字渐变效果下对标题文字默认、选中状态下颜色的记录
        if configure.titleGradientEffect {
            P_setupStartColor(color: configure.titleColor)
            P_setupEndColor(color: configure.titleSelectedColor)
        }
    }
}

// MARK: - 对外提供的方法
extension SGPageTitleView {
    /// 对外界提供的方法，获取 PageContent 的 progress／originalIndex／targetIndex
    func setPageTitleView(progress: CGFloat, originalIndex: Int, targetIndex: Int) {
        // 1、取出 originalBtn、targetBtn
        let originalBtn: UIButton = btnMArr[originalIndex]
        let targetBtn: UIButton = btnMArr[targetIndex]
        signBtnIndex = targetBtn.tag

        // 2、标题滚动样式下选中标题居中处理
        if allWidth > self.frame.size.width {
            if signBtnClick == false {
                self.P_selectedBtnCenter(button: targetBtn)
            }
            signBtnClick = false
        }
        // 3、处理指示器的逻辑
        if allWidth <= self.bounds.size.width { /// SGPageTitleView 静止样式
            if configure.indicatorScrollStyle == .Default {
                P_staticIndicatorScrollStyleDefault(progress: progress, originalBtn: originalBtn, targetBtn: targetBtn)
            } else {
                P_staticIndicatorScrollStyleHalfAndEnd(progress: progress, originalBtn: originalBtn, targetBtn: targetBtn)
            }
        } else { /// SGPageTitleView 可滚动
            if configure.indicatorScrollStyle == .Default {
                P_indicatorScrollStyleDefault(progress: progress, originalBtn: originalBtn, targetBtn: targetBtn)
            } else {
                P_indicatorScrollStyleHalfAndEnd(progress: progress, originalBtn: originalBtn, targetBtn: targetBtn)
            }
        }
        // 4、颜色的渐变(复杂)
        if configure.titleGradientEffect == true {
            P_titleGradientEffect(progress: progress, originalBtn: originalBtn, targetBtn: targetBtn)
        }
        // 5 、标题文字缩放属性(开启文字选中字号属性将不起作用)
        let configureTitleSelectedFont = configure.titleSelectedFont
        let defaultTitleFont = UIFont.systemFont(ofSize: 15)
        if configureTitleSelectedFont.fontName == defaultTitleFont.fontName && configureTitleSelectedFont.pointSize == defaultTitleFont.pointSize {
            if configure.titleTextZoom == true {
                // originalBtn 缩放
                let originalBtnZoomRatio = (1 - progress) * configure.titleTextZoomRatio
                originalBtn.transform = CGAffineTransform(scaleX: originalBtnZoomRatio + 1, y: originalBtnZoomRatio + 1)
                // targetBtn 缩放
                let targetBtnZoomRatio = progress * configure.titleTextZoomRatio
                targetBtn.transform = CGAffineTransform(scaleX: targetBtnZoomRatio + 1, y: targetBtnZoomRatio + 1)
            }
        }
    }
}

// MARK: - 对外提供的方法（badge 添加与删除）
extension SGPageTitleView {
    /// 根据标题下标值添加 badge
    func addBadge(index: Int) {
        let btn = btnMArr[index]

        let badge = UIView()
        badge.layer.backgroundColor = configure.badgeColor.cgColor
        badge.layer.cornerRadius = CGFloat(0.5 * configure.badgeSize)
        badge.tag = 2018 + index
        let btnTextWidth = P_size(string: btn.currentTitle!, font: configure.titleFont).width
        let btnTextHeight = P_size(string: btn.currentTitle!, font: configure.titleFont).height

        let badgeX = 0.5 * (btn.frame.size.width - btnTextWidth) + btnTextWidth + configure.badgeOff.x
        let badgeY = 0.5 * (btn.frame.size.height - btnTextHeight) + configure.badgeOff.y - configure.badgeSize
        let badgeWidth = configure.badgeSize
        let badgeHeight = badgeWidth
        badge.frame = CGRect(x: badgeX, y: badgeY, width: badgeWidth, height: badgeHeight)
        btn.addSubview(badge)
    }
    /// 根据标题下标值移除 badge
    func removeBadge(index: Int) {
        let btn = btnMArr[index]
        btn.subviews.forEach { (button) in
            if button.tag != 0 {
                button.removeFromSuperview()
            }
        }
    }
}

// MARK: - 对外提供的方法（重置标题文字、标题文字颜色及指示器颜色）
extension SGPageTitleView {
    /// 根据标题下标值重置标题文字
    func resetTitle(title: String, index: Int) {
        let btn = btnMArr[index]
        btn.setTitle(title, for: .normal)
        if self.signBtnIndex == index {
            if configure.indicatorStyle == .Default || configure.indicatorStyle == .Cover {
                let tempSize = P_size(string: btn.currentTitle!, font: configure.titleFont)
                var tempIndicatorWidth = configure.indicatorAdditionalWidth + tempSize.width
                if tempIndicatorWidth > btn.frame.size.width {
                    tempIndicatorWidth = btn.frame.size.width
                }
                indicator.frame.size.width = tempIndicatorWidth
                indicator.center.x = btn.center.x
            }
        }
    }
    /// 重置指示器颜色
    func resetIndicatorColor(color: UIColor) {
        indicator.backgroundColor = color
    }
    /// 重置标题普通状态、选中状态下文字颜色
    func resetTitleColor(color: UIColor, selectedColor: UIColor) {
        btnMArr.forEach { (button) in
            button.setTitleColor(color, for: .normal)
            button.setTitleColor(selectedColor, for: .selected)
        }
    }
    /// 重置标题普通状态、选中状态下文字颜色及指示器颜色方法
    func resetTitleColor(color: UIColor, selectedColor: UIColor, indicatorColor: UIColor) {
        resetTitleColor(color: color, selectedColor: selectedColor)
        resetIndicatorColor(color: indicatorColor)
    }
}

// MARK: - 内部方法
extension SGPageTitleView {
    private func P_size(string: String, font: UIFont) -> CGSize {
        let attrDict = [NSAttributedString.Key.font: font]
        let attrString = NSAttributedString(string: string, attributes: attrDict)
        return attrString.boundingRect(with: CGSize(width: 0, height: 0), options: .usesLineFragmentOrigin, context: nil).size
    }
    
    @objc private func P_btn_action(button: UIButton) {
        // 1、改变按钮的选择状态
        P_changeSelectedButton(button: button)
        // 2、标题滚动样式下选中标题居中处理
        if allWidth > self.frame.size.width {
            signBtnClick = true
            P_selectedBtnCenter(button: button)
        }
        // 3、改变有关指示器的相关操作
        P_changeIndicatorWithButton(button: button)
        // 4、CoatTitleViewProtocol
        if delegateTitleView != nil {
            delegateTitleView?.pageTitleView(pageTitleView: self, index: button.tag)
        }
        // 5、标记按钮下标
        signBtnIndex = button.tag
    }
    
    /// 改变按钮的选择状态
    private func P_changeSelectedButton(button: UIButton) {
        if tempBtn == nil {
            button.isSelected =  true
            tempBtn = button
        } else if tempBtn != nil && tempBtn == button {
            button.isSelected = true
        } else if tempBtn != nil && tempBtn != button {
            tempBtn!.isSelected = false
            button.isSelected = true
            tempBtn = button
        }
        
        let configureTitleSelectedFont = configure.titleSelectedFont
        let defaultTitleFont = UIFont.systemFont(ofSize: 15)
        if configureTitleSelectedFont.fontName == defaultTitleFont.fontName && configureTitleSelectedFont.pointSize == defaultTitleFont.pointSize {
            // 标题文字缩放属性(开启 titleSelectedFont 属性将不起作用)
            if configure.titleTextZoom == true {
                btnMArr.forEach { (button) in
                    button.transform = .identity
                }
                let afterZoomRatio: CGFloat = 1 + configure.titleTextZoomRatio
                button.transform = CGAffineTransform(scaleX: afterZoomRatio, y: afterZoomRatio)
            }
            
            // 此处作用：避免滚动过程中点击标题手指不离开屏幕的前提下再次滚动造成的误差（由于文字渐变效果导致未选中标题的不准确处理）
            if configure.titleGradientEffect == true {
                btnMArr.forEach { (button) in
                    button.titleLabel?.textColor = configure.titleColor
                }
                button.titleLabel?.textColor = configure.titleSelectedColor
            }
        } else {
            // 此处作用：避免滚动过程中点击标题手指不离开屏幕的前提下再次滚动造成的误差（由于文字渐变效果导致未选中标题的不准确处理）
            if configure.titleGradientEffect == true {
                btnMArr.forEach { (button) in
                    button.titleLabel?.textColor = configure.titleColor
                    button.titleLabel?.font = configure.titleFont
                }
                button.titleLabel?.textColor = configure.titleSelectedColor
                button.titleLabel?.font = configure.titleSelectedFont
            } else {
                btnMArr.forEach { (button) in
                    button.titleLabel?.font = configure.titleFont
                }
                button.titleLabel?.font = configure.titleSelectedFont
            }
        }
    }
    /// 标题滚动样式下选中标题居中处理
    private func P_selectedBtnCenter(button: UIButton) {
        var offsetX = button.center.x - self.frame.size.width * 0.5
        if offsetX < 0 {
            offsetX = 0
        }
        let maxOffsetX = scrollView.contentSize.width - self.frame.size.width
        if offsetX > maxOffsetX {
            offsetX = maxOffsetX
        }
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
    }
    /// 改变有关指示器的相关操作
    private func P_changeIndicatorWithButton(button: UIButton) {
        UIView.animate(withDuration: configure.indicatorAnimationTime) {
            if self.configure.indicatorStyle == .Fixed {
                self.indicator.frame.size.width = self.configure.indicatorFixedWidth
                self.indicator.center.x = button.center.x
                return
            }
            
            if self.configure.indicatorStyle == .Dynamic {
                self.indicator.frame.size.width = self.configure.indicatorDynamicWidth
                self.indicator.center.x = button.center.x
                return
            }

            let tempSize = self.P_size(string: button.currentTitle!, font: self.configure.titleFont)
            var tempIndicatorWidth = self.configure.indicatorAdditionalWidth + tempSize.width
            if tempIndicatorWidth > button.frame.size.width {
                tempIndicatorWidth = button.frame.size.width
            }
            self.indicator.frame.size.width = tempIndicatorWidth
            self.indicator.center.x = button.center.x
        }
    }
}

// MARK: - 滚动与指示器处理
extension SGPageTitleView {
    /// 静止：内容默认滚动状态下，指示器位置处理
    private func P_staticIndicatorScrollStyleDefault(progress: CGFloat, originalBtn: UIButton, targetBtn: UIButton) {
        // 改变按钮的选择状态
        if progress >= 0.8 {
            P_changeSelectedButton(button: targetBtn)
        }
        
        /// 处理 IndicatorStyleFixed 样式
        if configure.indicatorStyle == .Fixed {
            let btnWidth = self.frame.size.width / CGFloat(titleNames.count)
            let targetBtnMaxX = CGFloat(targetBtn.tag + 1) * btnWidth
            let originalBtnMaxX = CGFloat(originalBtn.tag + 1) * btnWidth
            let targetBtnIndicatorX = targetBtnMaxX - 0.5 * (btnWidth - configure.indicatorFixedWidth) - configure.indicatorFixedWidth
            let originalBtnIndicatorX = originalBtnMaxX - 0.5 * (btnWidth - configure.indicatorFixedWidth) - configure.indicatorFixedWidth
            
            let totalOffsetX = targetBtnIndicatorX - originalBtnIndicatorX
            indicator.frame.origin.x = originalBtnIndicatorX + progress * totalOffsetX
            return
        }
        
        /// 处理 IndicatorStyleDynamic 样式
        if configure.indicatorStyle == .Dynamic {
            let originalBtnTag = originalBtn.tag
            let targetBtnTag = targetBtn.tag
            let btnWidth = self.frame.size.width / CGFloat(titleNames.count)
            let targetBtnMaxX = CGFloat(targetBtn.tag + 1) * btnWidth
            let originalBtnMaxX = CGFloat(originalBtn.tag + 1) * btnWidth
            
            if originalBtnTag <= targetBtnTag { // 往左滑
                if progress <= 0.5 {
                    indicator.frame.size.width = configure.indicatorDynamicWidth + 2 * progress * btnWidth
                } else {
                    let targetBtnIndicatorX = targetBtnMaxX - 0.5 * (btnWidth - configure.indicatorDynamicWidth) - configure.indicatorDynamicWidth
                    indicator.frame.origin.x = targetBtnIndicatorX + 2 * (progress - 1) * btnWidth
                    indicator.frame.size.width = configure.indicatorDynamicWidth + 2 * (1 - progress) * btnWidth
                }
            } else {
                if progress <= 0.5 {
                    let originalBtnIndicatorX = originalBtnMaxX - 0.5 * (btnWidth - configure.indicatorDynamicWidth) - configure.indicatorDynamicWidth
                    indicator.frame.origin.x = originalBtnIndicatorX - 2 * progress * btnWidth
                    indicator.frame.size.width = configure.indicatorDynamicWidth + 2 * progress * btnWidth
                } else {
                    let targetBtnIndicatorX = targetBtnMaxX - configure.indicatorDynamicWidth - 0.5 * (btnWidth - configure.indicatorDynamicWidth)
                    indicator.frame.origin.x = targetBtnIndicatorX
                    indicator.frame.size.width = configure.indicatorDynamicWidth + 2 * (1 - progress) * btnWidth
                }
            }
            return
        }
        
        /// 处理指示器下划线、遮盖样式
        let btnWidth = self.frame.size.width / CGFloat(titleNames.count)
        // 文字宽度
        let targetBtnTextWidth: CGFloat = P_size(string: targetBtn.currentTitle!, font: self.configure.titleFont).width
        let originalBtnTextWidth: CGFloat = P_size(string: originalBtn.currentTitle!, font: self.configure.titleFont).width
        var targetBtnMaxX: CGFloat = 0.0
        var originalBtnMaxX: CGFloat = 0.0

        if configure.titleTextZoom == true {
            targetBtnMaxX = CGFloat(targetBtn.tag + 1) * btnWidth
            originalBtnMaxX = CGFloat(originalBtn.tag + 1) * btnWidth
        } else {
            targetBtnMaxX = targetBtn.frame.maxX
            originalBtnMaxX = originalBtn.frame.maxX
        }
        let targetIndicatorX = targetBtnMaxX - targetBtnTextWidth - 0.5 * (btnWidth - targetBtnTextWidth + configure.indicatorAdditionalWidth)
        let originalIndicatorX = originalBtnMaxX - originalBtnTextWidth - 0.5 * (btnWidth - originalBtnTextWidth + configure.indicatorAdditionalWidth)
        let totalOffsetX = targetIndicatorX - originalIndicatorX
        
        /// 2、计算文字之间差值
        // targetBtn 文字右边的 x 值
        let targetBtnRightTextX = targetBtnMaxX - 0.5 * (btnWidth - targetBtnTextWidth)
        // originalBtn 文字右边的 x 值
        let originalBtnRightTextX = originalBtnMaxX - 0.5 * (btnWidth - originalBtnTextWidth)
        let totalRightTextDistance = targetBtnRightTextX - originalBtnRightTextX
        // 计算 indicatorView 滚动时 x 的偏移量
        let offsetX = totalOffsetX * progress
        // 计算 indicatorView 滚动时文字宽度的偏移量
        let distance = progress * (totalRightTextDistance - totalOffsetX)
        
        /// 3、计算 indicatorView 新的 frame
        indicator.frame.origin.x = originalIndicatorX + offsetX
        
        let tempIndicatorWidth = configure.indicatorAdditionalWidth + originalBtnTextWidth + distance
        if tempIndicatorWidth >= targetBtn.frame.size.width {
            let moveTotalX = targetBtn.frame.origin.x - originalBtn.frame.origin.x
            let moveX = moveTotalX * progress
            indicator.center.x = originalBtn.center.x + moveX
        } else {
            indicator.frame.size.width = tempIndicatorWidth
        }

    }
    /// 静止：内容滚动一半以及结束状态下，指示器位置处理
    private func P_staticIndicatorScrollStyleHalfAndEnd(progress: CGFloat, originalBtn: UIButton, targetBtn: UIButton) {
        /// 1、处理 IndicatorScrollStyleHalf 逻辑
        if configure.indicatorScrollStyle == .Half {
            // 1、处理 IndicatorStyleFixed 样式
            if configure.indicatorStyle == .Fixed {
                if progress >= 0.5 {
                    UIView.animate(withDuration: configure.indicatorAnimationTime) {
                        self.indicator.center.x = targetBtn.center.x
                        self.P_changeSelectedButton(button: targetBtn)
                    }
                } else {
                    UIView.animate(withDuration: configure.indicatorAnimationTime) {
                        self.indicator.center.x = originalBtn.center.x
                        self.P_changeSelectedButton(button: originalBtn)
                    }
                }
                return
            }
            
            // 2、处理指示器下划线、遮盖样式
            if progress >= 0.5 {
                let tempSize = P_size(string: targetBtn.currentTitle!, font: configure.titleFont)
                let tempIndicatorWidth = tempSize.width + configure.indicatorAdditionalWidth
                
                UIView.animate(withDuration: configure.indicatorAnimationTime) {
                    if tempIndicatorWidth >= targetBtn.frame.size.width {
                        self.indicator.frame.size.width = targetBtn.frame.size.width
                    } else {
                        self.indicator.frame.size.width = tempIndicatorWidth
                    }
                    self.indicator.center.x = targetBtn.center.x
                    self.P_changeSelectedButton(button: targetBtn)
                }
            } else {
                let tempSize = P_size(string: originalBtn.currentTitle!, font: configure.titleFont)
                let tempIndicatorWidth = tempSize.width + configure.indicatorAdditionalWidth
                
                UIView.animate(withDuration: configure.indicatorAnimationTime) {
                    if tempIndicatorWidth >= targetBtn.frame.size.width {
                        self.indicator.frame.size.width = originalBtn.frame.size.width
                    } else {
                        self.indicator.frame.size.width = tempIndicatorWidth
                    }
                    self.indicator.center.x = originalBtn.center.x
                    self.P_changeSelectedButton(button: originalBtn)
                }
            }
            return
        }
        
        
        /// 2、处理 SGIndicatorScrollStyleEnd 逻辑
        // 1、处理 SGIndicatorStyleFixed 样式
        if self.configure.indicatorStyle == .Fixed {
            if progress == 1.0 {
                UIView.animate(withDuration: configure.indicatorAnimationTime) {
                    self.indicator.center.x = targetBtn.center.x
                    self.P_changeSelectedButton(button: targetBtn)
                }
            } else {
                UIView.animate(withDuration: configure.indicatorAnimationTime) {
                    self.indicator.center.x = originalBtn.center.x
                    self.P_changeSelectedButton(button: originalBtn)
                }
            }
            return
        }

        // 2、处理指示器下划线、遮盖样式
        if progress == 1.0 {
            let tempSize = P_size(string: targetBtn.currentTitle!, font: configure.titleFont)
            let tempIndicatorWidth = tempSize.width + configure.indicatorAdditionalWidth
            
            UIView.animate(withDuration: configure.indicatorAnimationTime) {
                if tempIndicatorWidth >= targetBtn.frame.size.width {
                    self.indicator.frame.size.width = targetBtn.frame.size.width
                } else {
                    self.indicator.frame.size.width = tempIndicatorWidth
                }
                self.indicator.center.x = targetBtn.center.x
                self.P_changeSelectedButton(button: targetBtn)
            }
        } else {
            let tempSize = P_size(string: originalBtn.currentTitle!, font: configure.titleFont)
            let tempIndicatorWidth = tempSize.width + configure.indicatorAdditionalWidth
            
            UIView.animate(withDuration: configure.indicatorAnimationTime) {
                if tempIndicatorWidth >= targetBtn.frame.size.width {
                    self.indicator.frame.size.width = originalBtn.frame.size.width
                } else {
                    self.indicator.frame.size.width = tempIndicatorWidth
                }
                self.indicator.center.x = originalBtn.center.x
                self.P_changeSelectedButton(button: originalBtn)
            }
        }
    }
    
    /// 滚动：内容默认滚动状态下，指示器位置处理
    private func P_indicatorScrollStyleDefault(progress: CGFloat, originalBtn: UIButton, targetBtn: UIButton) {
        /// 改变按钮的选择状态
        if progress >= 0.8 {
            P_changeSelectedButton(button: targetBtn)
        }
        /// 处理 IndicatorStyleFixed 样式
        if configure.indicatorStyle == .Fixed {
            let targetIndicatorX = targetBtn.frame.maxX - 0.5 * (targetBtn.frame.size.width - configure.indicatorFixedWidth) - configure.indicatorFixedWidth
            let originalIndicatorX = originalBtn.frame.maxX - configure.indicatorFixedWidth - 0.5 * (originalBtn.frame.size.width - configure.indicatorFixedWidth)
            let totalOffsetX = targetIndicatorX - originalIndicatorX
            let offsetX = totalOffsetX * progress
            indicator.frame.origin.x = originalIndicatorX + offsetX
            return
        }
        
        /// 处理 IndicatorStyleDynamic 样式
        if self.configure.indicatorStyle == .Dynamic {
            let originalBtnTag = originalBtn.tag
            let targetBtnTag = targetBtn.tag
            if originalBtnTag <= targetBtnTag { // 往左滑
                // targetBtn 与 originalBtn 中心点之间的距离
                let btnCenterXDistance = targetBtn.center.x - originalBtn.center.x
                if progress <= 0.5 {
                    indicator.frame.size.width = 2 * progress * btnCenterXDistance + configure.indicatorDynamicWidth
                } else {
                    let targetBtnX = targetBtn.frame.maxX - configure.indicatorDynamicWidth - 0.5 * (targetBtn.frame.size.width - configure.indicatorDynamicWidth)
                    indicator.frame.origin.x = targetBtnX + 2 * (progress - 1) * btnCenterXDistance
                    indicator.frame.size.width = 2 * (1 - progress) * btnCenterXDistance + configure.indicatorDynamicWidth
                }
            } else {
                // originalBtn 与 targetBtn 中心点之间的距离
                let btnCenterXDistance = originalBtn.center.x - targetBtn.center.x
                if progress <= 0.5 {
                    let originalBtnX = originalBtn.frame.maxX - configure.indicatorDynamicWidth - 0.5 * (originalBtn.frame.size.width - configure.indicatorDynamicWidth)
                    indicator.frame.origin.x = originalBtnX - 2 * progress * btnCenterXDistance
                    indicator.frame.size.width = 2 * progress * btnCenterXDistance + configure.indicatorDynamicWidth
                } else {
                    let targetBtnX = targetBtn.frame.maxX - configure.indicatorDynamicWidth - 0.5 * (targetBtn.frame.size.width - configure.indicatorDynamicWidth)
                    indicator.frame.origin.x = targetBtnX
                    indicator.frame.size.width = 2 * (1 - progress) * btnCenterXDistance + configure.indicatorDynamicWidth
                }
            }
            return
        }
        
        /// 处理指示器下划线、遮盖样式
        if configure.titleTextZoom && configure.showIndicator {
            print("标题文字缩放属性与指示器下划线、遮盖样式下不兼容，但固定及动态样式下兼容")
            return
        }

        // 1、计算 targetBtn 与 originalBtn 之间的 x 差值
        let totalOffsetX = targetBtn.frame.origin.x - originalBtn.frame.origin.x
        // 2、计算 targetBtn 与 originalBtn 之间距离的差值
        let totalDistance = targetBtn.frame.maxX - originalBtn.frame.maxX
        /// 计算 indicator 滚动时 x 的偏移量
        var offsetX: CGFloat = 0.0
        /// 计算 indicator 滚动时宽度的偏移量
        var distance: CGFloat = 0.0

        let targetBtnTextWidth = P_size(string: targetBtn.currentTitle!, font: configure.titleFont).width
        let tempIndicatorWidth = configure.indicatorAdditionalWidth + targetBtnTextWidth
        if tempIndicatorWidth >= targetBtn.frame.size.width {
            offsetX = totalOffsetX * progress
            distance = progress * (totalDistance - totalOffsetX)
            indicator.frame.origin.x = originalBtn.frame.origin.x + offsetX
            indicator.frame.size.width = originalBtn.frame.size.width + distance
        } else {
            offsetX = totalOffsetX * progress + 0.5 * configure.titleAdditionalWidth - 0.5 * configure.indicatorAdditionalWidth
            distance = progress * (totalDistance - totalOffsetX) - configure.titleAdditionalWidth
            /// 计算 indicator 新的 frame
            indicator.frame.origin.x = originalBtn.frame.origin.x + offsetX
            indicator.frame.size.width = originalBtn.frame.size.width + distance + configure.indicatorAdditionalWidth
        }
    }
    /// 滚动：内容滚动一半以及结束状态下，指示器位置处理
    private func P_indicatorScrollStyleHalfAndEnd(progress: CGFloat, originalBtn: UIButton, targetBtn: UIButton) {
        /// 1、处理 IndicatorScrollStyleHalf 逻辑
        if configure.indicatorScrollStyle == .Half {
            // 1、处理 IndicatorStyleFixed 样式
            if configure.indicatorStyle == .Fixed {
                if progress >= 0.5 {
                    UIView.animate(withDuration: configure.indicatorAnimationTime) {
                        self.indicator.center.x = targetBtn.center.x
                        self.P_changeSelectedButton(button: targetBtn)
                    }
                } else {
                    UIView.animate(withDuration: configure.indicatorAnimationTime) {
                        self.indicator.center.x = originalBtn.center.x
                        self.P_changeSelectedButton(button: originalBtn)
                    }
                }
                return
            }

            // 2、处理指示器下划线、遮盖样式
            if progress >= 0.5 {
                let tempSize = P_size(string: targetBtn.currentTitle!, font: configure.titleFont)
                let tempIndicatorWidth = configure.indicatorAdditionalWidth + tempSize.width
                UIView.animate(withDuration: configure.indicatorAnimationTime) {
                    if tempIndicatorWidth >= targetBtn.frame.size.width {
                        self.indicator.frame.size.width = targetBtn.frame.size.width
                    } else {
                        self.indicator.frame.size.width = tempIndicatorWidth
                    }
                    self.indicator.center.x = targetBtn.center.x
                    self.P_changeSelectedButton(button: targetBtn)
                }
            } else {
                let tempSize = P_size(string: originalBtn.currentTitle!, font: configure.titleFont)
                let tempIndicatorWidth = configure.indicatorAdditionalWidth + tempSize.width
                UIView.animate(withDuration: configure.indicatorAnimationTime) {
                    if tempIndicatorWidth >= originalBtn.frame.size.width {
                        self.indicator.frame.size.width = originalBtn.frame.size.width
                    } else {
                        self.indicator.frame.size.width = tempIndicatorWidth
                    }
                    self.indicator.center.x = originalBtn.center.x
                    self.P_changeSelectedButton(button: targetBtn)
                }
            }
            return
        }


        /// 2、处理 IndicatorScrollStyleEnd 逻辑
        // 1、处理 IndicatorStyleFixed 样式
        if configure.indicatorStyle == .Fixed {
            if progress == 1.0 {
                UIView.animate(withDuration: configure.indicatorAnimationTime) {
                    self.indicator.center.x = targetBtn.center.x
                    self.P_changeSelectedButton(button: targetBtn)
                }
            } else {
                UIView.animate(withDuration: configure.indicatorAnimationTime) {
                    self.indicator.center.x = originalBtn.center.x
                    self.P_changeSelectedButton(button: originalBtn)
                }
            }
            return
        }

        // 2、处理指示器下划线、遮盖样式
        if progress == 1.0 {
            let tempSize = P_size(string: targetBtn.currentTitle!, font: configure.titleFont)
            let tempIndicatorWidth = configure.indicatorAdditionalWidth + tempSize.width
            UIView.animate(withDuration: configure.indicatorAnimationTime) {
                if tempIndicatorWidth >= targetBtn.frame.size.width {
                    self.indicator.frame.size.width = targetBtn.frame.size.width
                } else {
                    self.indicator.frame.size.width = tempIndicatorWidth
                }
                self.indicator.center.x = targetBtn.center.x
                self.P_changeSelectedButton(button: targetBtn)
            }
        } else {
            let tempSize = P_size(string: originalBtn.currentTitle!, font: configure.titleFont)
            let tempIndicatorWidth = configure.indicatorAdditionalWidth + tempSize.width
            UIView.animate(withDuration: configure.indicatorAnimationTime) {
                if tempIndicatorWidth >= originalBtn.frame.size.width {
                    self.indicator.frame.size.width = originalBtn.frame.size.width
                } else {
                    self.indicator.frame.size.width = tempIndicatorWidth
                }
                self.indicator.center.x = originalBtn.center.x
                self.P_changeSelectedButton(button: originalBtn)
            }
        }
    }
}

// MARK: - 颜色渐变方法
extension SGPageTitleView {
    private func P_titleGradientEffect(progress: CGFloat, originalBtn: UIButton, targetBtn: UIButton) {
        // 获取 targetProgress
        let targetProgress = progress
        // 获取 originalProgress
        let originalProgress = 1 - targetProgress
        
        let r = endR - startR
        let g = endG - startG
        let b = endB - startB
        let originalColor: UIColor = UIColor.init(red: startR +  r * originalProgress, green: startG +  g * originalProgress, blue: startB +  b * originalProgress, alpha: 1.0)
        let targetColor: UIColor = UIColor.init(red: startR + r * targetProgress, green: startG + g * targetProgress, blue: startB + b * targetProgress, alpha: 1.0)
        // 设置文字颜色渐变
        originalBtn.titleLabel?.textColor = originalColor
        targetBtn.titleLabel?.textColor = targetColor
    }
}

// MARK: - 颜色设置方法
extension SGPageTitleView {
    private func P_setupStartColor(color: UIColor) {
        let components = getRGBComponents(color: color)
        startR = components[0]
        startG = components[1]
        startB = components[2]
    }
    private func P_setupEndColor(color: UIColor) {
        let components = getRGBComponents(color: color)
        endR = components[0]
        endG = components[1]
        endB = components[2]
    }
    
    private func getRGBComponents(color: UIColor) -> [CGFloat] {
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let data = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: 4)
        let context = CGContext(data: data, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: rgbColorSpace, bitmapInfo: 1)
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect.init(x: 0, y: 0, width: 1, height: 1))
        var components:[CGFloat] = []
        for i in 0..<3 {
            components.append(CGFloat(data[i])/255.0)
        }
        return components
    }
}

