@main
public class LandinhoBot {
  init(bot: DefaultVroomBot) {
    self.bot = bot
  }
  let bot: DefaultVroomBot
}

extension LandinhoBot {
  public static func main() {
    _ = LandinhoBot(bot: .init())
  }
}



