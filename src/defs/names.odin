package defs

import "core:reflect"
import "core:log"

name_display :: proc(name: Name) -> string {
	switch name {
	case .Hale:
		return "Hale"
	case .Judy:
		return "Judy"
	case .Trudy:
		return "Trudy"
	case .Anthony:
		return "Anthony"
	case .Bellweather:
		return "Bellweather"
	case .LawStudent:
		return "Law Student"
	case .LawProfessor:
		return "Law Professor"
	case .DeanOfLaw:
		return "Dean of Law"
	case .Bailiff:
		return "Bailiff"
	case .Sheriff:
		return "Sheriff"
	case .SupremeCourtJustice:
		return "Supreme Court Justice"
	case .CircuitJudge:
		return "Circuit Judge"
	case .DistrictJudge:
		return "District Judge"
	case .MagistrateJudge:
		return "Magistrate Judge"
	case .BankruptcyJudge:
		return "Bankruptcy Judge"
	case .AppellateJudge:
		return "Appellate Judge"
	case .Clerk:
		return "Clerk"
	case .CourtReporter:
		return "Court Reporter"
	case .Stenographers:
		return "Stenographers"
	case .ProbationOfficer:
		return "Probation Officer"
	case .Interpreter:
		return "Interpreter"
	case .LawLibrarian:
		return "Law Librarian"
	case .LegalSecretary:
		return "Legal Secretary"
	case .JuryConsultant:
		return "Jury Consultant"
	case .DistrictAttorney:
		return "District Attorney"
	case .CountyCommissioner:
		return "County Commissioner"
	case .Prosecutor:
		return "Prosecutor"
	case .Defense:
		return "Defense"
	case .CorporateAttorney:
		return "Corporate Attorney"
	case .FamilyLawAttorney:
		return "Family Law Attorney"
	case .PatentAttorney:
		return "Patent Attorney"
	case .ImmigrationAttorney:
		return "Immigration Attorney"
	case .PublicDefenseAttorney:
		return "Public Defense Attorney"
	case .JudgeAdvocateGeneral:
		return "Judge Advocate General"
	}

	log.error("Unknown name found for display; returning 'Unknown'.")	
	return "Unknown"
}

name_base :: proc(name: Name) -> string {
	return reflect.enum_string(name)
}

item_name_display :: proc(name: Item_Name) -> string {
	if name == .NoItem {
		return "NoItem"
	}

	if name == .Unarmed {
		return "Unarmed"
	}

	return spaced_camel(reflect.enum_string(name))
}

@(private = "file")
spaced_camel :: proc(raw: string) -> string {
	if len(raw) == 0 {
		return raw
	}

	extra := 0
	for i in 1 ..< len(raw) {
		ch := raw[i]
		if ch >= 'A' && ch <= 'Z' {
			extra += 1
		}
	}

	buf := make([]u8, len(raw) + extra, context.temp_allocator)
	out := 0
	buf[out] = raw[0]
	out += 1
	for i in 1 ..< len(raw) {
		ch := raw[i]
		if ch >= 'A' && ch <= 'Z' {
			buf[out] = ' '
			out += 1
		}

		buf[out] = ch
		out += 1
	}

	return string(buf[:out])
}

magic_family_base :: proc(family: Magic_Family) -> string {
	return reflect.enum_string(family)
}

direction_walk_image :: proc(direction: Direction) -> string {
	switch direction {
	case .Up:
		return "WalkUp.png"
	case .Right:
		return "WalkRight.png"
	case .Down:
		return "WalkDown.png"
	case .Left:
		return "WalkLeft.png"
	}

	return "WalkDown.png"
}
