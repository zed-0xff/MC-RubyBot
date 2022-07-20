// originally from https://github.com/Moulberry/NotEnoughUpdates
// shortened, adapted for fabric
package net.fabricmc.example.utils;

import net.minecraft.util.StringHelper;

import com.google.common.base.Splitter;

import java.util.HashMap;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class XPInformation {
	private static final XPInformation INSTANCE = new XPInformation();

	public static XPInformation getInstance() {
		return INSTANCE;
	}

	public static class SkillInfo {
		public int level;
		public float deltaXp;
		public float currentXp;
		public float currentXpMax;
	}

	private final HashMap<String, SkillInfo> initials = new HashMap<>();
	private final HashMap<String, SkillInfo> skillInfoMap = new HashMap<>();
	public HashMap<String, Float> updateWithPercentage = new HashMap<>();

	public int correctionCounter = 0;

	private static final Splitter SPACE_SPLITTER = Splitter.on("  ").omitEmptyStrings().trimResults();
	private static final Pattern SKILL_PATTERN = Pattern.compile(
		"\\+(\\d+(?:,\\d+)*(?:\\.\\d+)?) (.+) \\((\\d+(?:,\\d+)*(?:\\.\\d+)?)/(\\d+(?:,\\d+)*(?:\\.\\d+)?)\\)");
	private static final Pattern SKILL_PATTERN_MULTIPLIER =
		Pattern.compile("\\+(\\d+(?:,\\d+)*(?:\\.\\d+)?) (.+) \\((\\d+(?:,\\d+)*(?:\\.\\d+)?)/(\\d+(?:k|m|b))\\)");
	private static final Pattern SKILL_PATTERN_PERCENTAGE =
		Pattern.compile("\\+(\\d+(?:,\\d+)*(?:\\.\\d+)?) (.+) \\((\\d\\d?(?:\\.\\d\\d?)?)%\\)");

	public HashMap<String, SkillInfo> getSkillInfoMap() {
		return skillInfoMap;
	}

    public static String cleanColour(String in) {
        return in.replaceAll("(?i)\\u00A7.", "");
    }

    private String lastActionBar = null;

    public void onChatReceived(String msg) {
        String actionBar = cleanColour(StringHelper.stripTextFormat(msg));

        if (lastActionBar != null && lastActionBar.equalsIgnoreCase(actionBar)) {
            return;
        }
        lastActionBar = actionBar;

        List<String> components = SPACE_SPLITTER.splitToList(msg);
        String skillS = null;
        SkillInfo skillInfo = null;

        for (String component : components) {
            if ( component.startsWith("§3" ))
                component = component.substring(2);
            Matcher matcher = SKILL_PATTERN.matcher(component);
            if (matcher.matches()) {
                String deltaXpS = matcher.group(1).replace(",", "");
                skillS = matcher.group(2);
                String currentXpS = matcher.group(3).replace(",", "");
                String maxXpS = matcher.group(4).replace(",", "");

                skillInfo = new SkillInfo();
                skillInfo.deltaXp = Float.parseFloat(deltaXpS);
                skillInfo.currentXp = Float.parseFloat(currentXpS);
                skillInfo.currentXpMax = Float.parseFloat(maxXpS);
                break;
            } else {
                matcher = SKILL_PATTERN_PERCENTAGE.matcher(component);
                if (matcher.matches()) {
                    skillS = matcher.group(2);
                    String xpPercentageS = matcher.group(3).replace(",", "");

                    float xpPercentage = Float.parseFloat(xpPercentageS);
                    updateWithPercentage.put(skillS, xpPercentage);
                } else {
                    matcher = SKILL_PATTERN_MULTIPLIER.matcher(component);

                    if (matcher.matches()) {
                        String deltaXpS = matcher.group(1).replace(",", "");
                        skillS = matcher.group(2);
                        String currentXpS = matcher.group(3).replace(",", "");
                        String maxXpS = matcher.group(4).replace(",", "");

                        float maxMult = 1;
                        if (maxXpS.endsWith("k")) {
                            maxMult = 1000;
                            maxXpS = maxXpS.substring(0, maxXpS.length() - 1);
                        } else if (maxXpS.endsWith("m")) {
                            maxMult = 1000000;
                            maxXpS = maxXpS.substring(0, maxXpS.length() - 1);
                        } else if (maxXpS.endsWith("b")) {
                            maxMult = 1000000000;
                            maxXpS = maxXpS.substring(0, maxXpS.length() - 1);
                        }

                        skillInfo = new SkillInfo();
                        skillInfo.deltaXp = Float.parseFloat(deltaXpS);
                        skillInfo.currentXp = Float.parseFloat(currentXpS);
                        skillInfo.currentXpMax = Float.parseFloat(maxXpS) * maxMult;
                        break;
                    }
                }
            }
        }
        if ( skillInfo != null ) {
            SkillInfo prev = skillInfoMap.get(skillS);
            if ( prev != null ) {
                skillInfo.deltaXp += prev.deltaXp;
            }
            skillInfoMap.put(skillS, skillInfo);
        }
    }

}
