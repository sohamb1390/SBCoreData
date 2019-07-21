//
//  UserCell.swift
//  SBCoreData
//
//  Created by Soham Bhattacharjee on 21/07/19.
//  Copyright © 2019 Soham Bhattacharjee. All rights reserved.
//

import UIKit

class UserCell: UITableViewCell {

    // MARK: IBOutlets
    @IBOutlet weak var nameLabeL: UILabel!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var dobLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    // MARK: Variables
    private (set) var viewModel: UserCellViewModel?
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func bind(vm: UserCellViewModel) {
        self.viewModel = vm
        self.nameLabeL.text = self.viewModel?.userName
        self.genderLabel.text = self.viewModel?.gender
        self.dobLabel.text = self.viewModel?.dob
        self.addressLabel.text = self.viewModel?.address
    }
}
