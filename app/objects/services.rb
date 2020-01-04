class Services
  def recount_trusts(group)
    X.transaction do
      gmembers = group.query_gmembers({ pagination: X.get_pagination("dont") })
      gmembers.each do |gmember|
        trust_count = X.queries.count_trust(gmember)
        trustee = gmember.query_trustee
        gmember.trust_count = trust_count
        gmember.trustee = trustee
        gmember.save!
      end
    end
  end

  def recount_towers(group)
    X.transaction do
      gmembers = group.query_gmembers({ pagination: X.get_pagination("dont") })
      gmembers.each do |gmember|
        tower_top = X.queries.tower_top_from_trust({ gmember: gmember })
        gmember.tower_top = tower_top
        gmember.save!
      end
      tower_tops = gmembers.map(&:tower_top).compact
      gmembers.each do |gmember|
        if gmember.tower_top.nil?
          if tower_tops.include?(gmember)
            gmember.tower_top = gmember
            gmember.save!
          end
        end
      end
    end
  end

  def recount_group_gmembers(group)
    group.members_count = X.queries.count_gmembers(group)
    group.save!
  end

  def delete_account(user)
    gmembers = user.query_gmembers

    X.transaction do
      gmembers.each do |gmember|
        delete_gmember(gmember)
      end

      user.set_deleted_at_now
      user.set_deleted_status
      user.set_email_nil
      user.save!
    end

    X.transaction do
      gmembers.map(&:group).each do |group|
        recount_trusts(group)
        recount_towers(group)
        recount_group_gmembers(group)
      end
    end
    self
  end

  def join_group(group, users)
    users = Array(users)
    X.transaction do
      users.map do |user|
        gmember = X.queries.find_gmember({ group: group, member: user, with_deleted: true })
        if gmember.nil?
          gmember = X.factory.build("gmember")
          gmember.group = group
          gmember.member = user
          gmember.set_status_active
          gmember.start_trust_count
          gmember.set_color X.generate_color
          gmember.save!
        elsif gmember.status_active?
          # procced
        elsif gmember.status_deleted?
          gmember.tower_top = nil
          gmember.set_status_active
          gmember.start_trust_count
          gmember.save!
        else fail
        end
      end

      recount_group_gmembers(group)
    end
    self
  end

  def trust_back(a)
    if a.is_a?(Trust)
      truster = a.truster
    elsif a.is_a?(GroupMembership)
      truster = a
    else fail
    end

    X.transaction do
      trust = truster.current_trust
      if trust
        truster.tower_top = nil
        truster.trustee = nil
        truster.save!
        trust.set_status_old
        trust.expire_now
        trust.save!
      end
    end
    self
  end

  def delete_gmember(gmember)
    trusts_on = X.queries.trusts_on(gmember, { group: gmember.group })
    trusts_of = X.queries.trusts_of({ gmember: gmember })

    trusts_on.each do |trust|
      trust.set_status_old
      trust.save!
    end
    trusts_of.each do |trust|
      trust.set_status_old
      trust.save!
    end

    gmember.set_status_deleted
    gmember.save!
    self
  end

  def recount_everything
    groups = X.queries.all_groups
    groups.each do |group|
      X.transaction do
        recount_trusts(group)
        recount_towers(group)
        recount_group_gmembers(group)
      end
    end
  end
end